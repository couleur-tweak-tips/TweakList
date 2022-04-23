# This file is automatically built at every commit to add up every function to a single file, this makes it simplier to parse (aka download) and execute.

$CommitCount = 55
$FuncsCount = 34
<#
The MIT License (MIT)

Copyright (c) 2019 Oliver Lipkau

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

Function Get-IniContent {
    <#
    .Synopsis
        Gets the content of an INI file

    .Description
        Gets the content of an INI file and returns it as a hashtable

    .Notes
        Author		: Oliver Lipkau <oliver@lipkau.net>
		Source		: https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version		: 1.0.0 - 2010/03/12 - OL - Initial release
                      1.0.1 - 2014/12/11 - OL - Typo (Thx SLDR)
                                              Typo (Thx Dave Stiff)
                      1.0.2 - 2015/06/06 - OL - Improvment to switch (Thx Tallandtree)
                      1.0.3 - 2015/06/18 - OL - Migrate to semantic versioning (GitHub issue#4)
                      1.0.4 - 2015/06/18 - OL - Remove check for .ini extension (GitHub Issue#6)
                      1.1.0 - 2015/07/14 - CB - Improve round-tripping and be a bit more liberal (GitHub Pull #7)
                                           OL - Small Improvments and cleanup
                      1.1.1 - 2015/07/14 - CB - changed .outputs section to be OrderedDictionary
                      1.1.2 - 2016/08/18 - SS - Add some more verbose outputs as the ini is parsed,
                      				            allow non-existent paths for new ini handling,
                      				            test for variable existence using local scope,
                      				            added additional debug output.

        #Requires -Version 2.0

    .Inputs
        System.String

    .Outputs
        System.Collections.Specialized.OrderedDictionary

    .Example
        $FileContent = Get-IniContent "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent

    .Example
        $inifilepath | $FileContent = Get-IniContent
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent

    .Example
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file

    .Link
        Out-IniFile
    #>

    [CmdletBinding()]
    [OutputType(
        [System.Collections.Specialized.OrderedDictionary]
    )]
    Param(
        # Specifies the path to the input file.
        [ValidateNotNullOrEmpty()]
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        [String]
        $FilePath,

        # Specify what characters should be describe a comment.
        # Lines starting with the characters provided will be rendered as comments.
        # Default: ";"
        [Char[]]
        $CommentChar = @(";"),

        # Remove lines determined to be comments from the resulting dictionary.
        [Switch]
        $IgnoreComments
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $commentRegex = "^\s*([$($CommentChar -join '')].*)$"
        $sectionRegex = "^\s*\[(.+)\]\s*$"
        $keyRegex     = "^\s*(.+?)\s*=\s*(['`"]?)(.*)\2\s*$"

        Write-Debug ("commentRegex is {0}." -f $commentRegex)
    }

    Process {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

        $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        #$ini = @{}

        if (!(Test-Path $Filepath)) {
            Write-Verbose ("Warning: `"{0}`" was not found." -f $Filepath)
            Write-Output $ini
        }

        $commentCount = 0
        switch -regex -file $FilePath {
            $sectionRegex {
                # Section
                $section = $matches[1]
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding section : $section"
                $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                $CommentCount = 0
                continue
            }
            $commentRegex {
                # Comment
                if (!$IgnoreComments) {
                    if (!(test-path "variable:local:section")) {
                        $section = $script:NoSection
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    }
                    $value = $matches[1]
                    $CommentCount++
                    Write-Debug ("Incremented CommentCount is now {0}." -f $CommentCount)
                    $name = "Comment" + $CommentCount
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding $name with value: $value"
                    $ini[$section][$name] = $value
                }
                else {
                    Write-Debug ("Ignoring comment {0}." -f $matches[1])
                }

                continue
            }
            $keyRegex {
                # Key
                if (!(test-path "variable:local:section")) {
                    $section = $script:NoSection
                    $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                }
                $name, $value = $matches[1, 3]
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding key $name with value: $value"
                if (-not $ini[$section][$name]) {
                    $ini[$section][$name] = $value
                }
                else {
                    if ($ini[$section][$name] -is [string]) {
                        $ini[$section][$name] = [System.Collections.ArrayList]::new()
                        $ini[$section][$name].Add($ini[$section][$name]) | Out-Null
                        $ini[$section][$name].Add($value) | Out-Null
                    }
                    else {
                        $ini[$section][$name].Add($value) | Out-Null
                    }
                }
                continue
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
        Write-Output $ini
    }

    End {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias gic Get-IniContent
<#
The MIT License (MIT)

Copyright (c) 2019 Oliver Lipkau

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>
Function Out-IniFile {
    <#
    .Synopsis
        Write hash content to INI file

    .Description
        Write hash content to INI file

    .Notes
        Author      : Oliver Lipkau <oliver@lipkau.net>
        Blog        : http://oliver.lipkau.net/blog/
        Source      : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91

        #Requires -Version 2.0

    .Inputs
        System.String
        System.Collections.IDictionary

    .Outputs
        System.IO.FileSystemInfo

    .Example
        Out-IniFile $IniVar "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini

    .Example
        $IniVar | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present

    .Example
        $file = Out-IniFile $IniVar "C:\myinifile.ini" -PassThru
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file

    .Example
        $Category1 = @{“Key1”=”Value1”;”Key2”=”Value2”}
        $Category2 = @{“Key1”=”Value1”;”Key2”=”Value2”}
        $NewINIContent = @{“Category1”=$Category1;”Category2”=$Category2}
        Out-IniFile -InputObject $NewINIContent -FilePath "C:\MyNewFile.ini"
        -----------
        Description
        Creating a custom Hashtable and saving it to C:\MyNewFile.ini
    .Link
        Get-IniContent
    #>

    [CmdletBinding()]
    [OutputType(
        [System.IO.FileSystemInfo]
    )]
    Param(
        # Adds the output to the end of an existing file, instead of replacing the file contents.
        [switch]
        $Append,

        # Specifies the file encoding. The default is UTF8.
        #
        # Valid values are:
        # -- ASCII:  Uses the encoding for the ASCII (7-bit) character set.
        # -- BigEndianUnicode:  Encodes in UTF-16 format using the big-endian byte order.
        # -- Byte:   Encodes a set of characters into a sequence of bytes.
        # -- String:  Uses the encoding type for a string.
        # -- Unicode:  Encodes in UTF-16 format using the little-endian byte order.
        # -- UTF7:   Encodes in UTF-7 format.
        # -- UTF8:  Encodes in UTF-8 format.
        [ValidateSet("Unicode", "UTF7", "UTF8", "ASCII", "BigEndianUnicode", "Byte", "String")]
        [Parameter()]
        [String]
        $Encoding = "UTF8",

        # Specifies the path to the output file.
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {Test-Path $_ -IsValid} )]
        [Parameter( Position = 0, Mandatory = $true )]
        [String]
        $FilePath,

        # Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.
        [Switch]
        $Force,

        # Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        [System.Collections.IDictionary]
        $InputObject,

        # Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.
        [Switch]
        $Passthru,

        # Adds spaces around the equal sign when writing the key = value
        [Switch]
        $Loose,

        # Writes the file as "pretty" as possible
        #
        # Adds an extra linebreak between Sections
        [Switch]
        $Pretty
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        function Out-Keys {
            param(
                [ValidateNotNullOrEmpty()]
                [Parameter( Mandatory, ValueFromPipeline )]
                [System.Collections.IDictionary]
                $InputObject,

                [ValidateSet("Unicode", "UTF7", "UTF8", "ASCII", "BigEndianUnicode", "Byte", "String")]
                [Parameter( Mandatory )]
                [string]
                $Encoding = "UTF8",

                [ValidateNotNullOrEmpty()]
                [ValidateScript( {Test-Path $_ -IsValid})]
                [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
                [Alias("Path")]
                [string]
                $FilePath,

                [Parameter( Mandatory )]
                $Delimiter,

                [Parameter( Mandatory )]
                $MyInvocation
            )

            Process {
                if (!($InputObject.get_keys())) {
                    Write-Warning ("No data found in '{0}'." -f $FilePath)
                }
                Foreach ($key in $InputObject.get_keys()) {
                    if ($key -match "^Comment\d+") {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $key"
                        "$($InputObject[$key])" | Out-File -Encoding $Encoding -FilePath $FilePath -Append
                    }
                    else {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key"
                        $InputObject[$key] |
                            ForEach-Object { "$key$delimiter$_" } |
                            Out-File -Encoding $Encoding -FilePath $FilePath -Append
                    }
                }
            }
        }

        $delimiter = '='
        if ($Loose) {
            $delimiter = ' = '
        }

        # Splatting Parameters
        $parameters = @{
            Encoding = $Encoding;
            FilePath = $FilePath
        }

    }

    Process {
        $extraLF = ""

        if ($Append) {
            Write-Debug ("Appending to '{0}'." -f $FilePath)
            $outfile = Get-Item $FilePath
        }
        else {
            Write-Debug ("Creating new file '{0}'." -f $FilePath)
            $outFile = New-Item -ItemType file -Path $Filepath -Force:$Force
        }

        if (!(Test-Path $outFile.FullName)) {Throw "Could not create File"}

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"
        foreach ($i in $InputObject.get_keys()) {
            if (!($InputObject[$i].GetType().GetInterface('IDictionary'))) {
                #Key value pair
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"
                "$i$delimiter$($InputObject[$i])" | Out-File -Append @parameters

            }
            elseif ($i -eq $script:NoSection) {
                #Key value pair of NoSection
                Out-Keys $InputObject[$i] `
                    @parameters `
                    -Delimiter $delimiter `
                    -MyInvocation $MyInvocation
            }
            else {
                #Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"

                # Only write section, if it is not a dummy ($script:NoSection)
                if ($i -ne $script:NoSection) { "$extraLF[$i]"  | Out-File -Append @parameters }
                if ($Pretty) {
                    $extraLF = "`r`n"
                }

                if ( $InputObject[$i].Count) {
                    Out-Keys $InputObject[$i] `
                        @parameters `
                        -Delimiter $delimiter `
                        -MyInvocation $MyInvocation
                }

            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $FilePath"
    }

    End {
        if ($PassThru) {
            Write-Debug ("Returning file due to PassThru argument.")
            Write-Output (Get-Item $outFile)
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias oif Out-IniFile
function Assert-Choice {
    if (-Not(Get-Command choice.exe -ErrorAction Ignore)){
        Write-Host "[!] Unable to find choice.exe (it comes with Windows, did a little bit of unecessary debloating?)" -ForegroundColor Red
        PauseNul
        exit 1
    }
}
function Assert-Path ($Path) {
    if (-Not(Test-Path -Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}
function Get-7zPath {

    if (Get-Command 7z.exe -Ea Ignore){return (Get-Command 7z.exe).Source}

    $DefaultPath = "$env:ProgramFiles\7-Zip\7z.exe"
    if (Test-Path $DefaultPath) {return $DefaultPath}

    Try {
        $InstallLocation = (Get-Package 7-Zip* -ErrorAction Stop).Metadata['InstallLocation'] # Compatible with 7-Zip installed normally / with winget
        if (Test-Path $InstallLocation -ErrorAction Stop){
            return "$InstallLocation`7z.exe"
        }
    }Catch{} # If there's an error it's probably not installed anyways

    if (Get-Boolean "7-Zip could not be found, would you like to download it using Scoop?"){
        Install-Scoop
        scoop install 7zip
        if (Get-Command 7z -Ea Ignore){
            return (Get-Command 7z.exe).Source
        }else{
            Write-Error "7-Zip could not be installed"
            return 
        }

    }else{return}

    # leaving this here if anyone knows a smart way to implement this ))
    # $7Zip = (Get-ChildItem -Path "$env:HOMEDRIVE\*7z.exe" -Recurse -Force -ErrorAction Ignore).FullName | Select-Object -First 1

}
function Get-Boolean ($Message){
    $null = $Response
    While ($Response -NotIn 'yes','y','n','no'){
        Write-Host "Answer must be 'yes','y','n' or 'no'" -ForegroundColor Red
        $Response = Read-Host $Message
    }
    if ($Response -in 'yes','y'){return $true}
    elseif($Response -in 'n','no'){return $false}
    else{Write-Error "Invalid response";pause;exit}
}

function Get-EncodingArgs{
    [alias('genca')]
    param(
        [Switch]$Silent
    )

Install-FFmpeg

$DriverVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}_Display.Driver" -ErrorAction Ignore).DisplayVersion
    if ($DriverVersion){ # Only triggers if it parsed a NVIDIA driver version
        if ($DriverVersion -lt 477.41){ # Oldest NVIDIA version capable
        Write-Warning "Outdated NVIDIA Drivers detected ($DriverVersion), NVIDIA settings won't be available until you upgrade your drivers"
    }
}

@(
    'hevc_nvenc -rc constqp -preset p7 -qp 18'
    'h264_nvenc -rc constqp -preset p7 -qp 15'
    'hevc_amf -quality quality -qp_i 16 -qp_p 18 -qp_b 20'
    'h264_amf -quality quality -qp_i 12 -qp_p 12 -qp_b 12'
    'hevc_qsv -preset veryslow -global_quality:v 18'
    'h264_qsv -preset veryslow -global_quality:v 15'
    'libx265 -preset medium -crf 18'
    'libx264 -preset slow -crf 15'
) | ForEach-Object -Begin {
    $script:shouldStop = $false
} -Process {
    if ($shouldStop -eq $true) { return }
    Invoke-Expression "ffmpeg.exe -loglevel fatal -f lavfi -i nullsrc=3840x2160 -t 0.1 -c:v $_ -f null NUL"
    if ($LASTEXITCODE -eq 0){
        $script:valid_args = $_

        if ($Silent){
            Write-Host ("Found compatible encoding settings: {0}" -f $script:valid_args.Split(' ')[0].Replace('_', ' ').ToUpper()) -ForegroundColor Green
        }
        $shouldStop = $true # Crappy way to stop the loop since most people that'll execute this will technically be parsing the raw URL as a scriptblock
    }
}

if (-Not($script:valid_args)){
    Write-Host "No compatible encoding settings found (should not happen, is FFmpeg installed?)" -ForegroundColor DarkRed
    Get-Command FFmpeg -Ea Ignore
    Pause
    exit
}

return $valid_args

}
function Get-FunctionContent {
    [alias('gfc')]
    param([Parameter()][String]$FunctionName)
    return (Get-Command $FunctionName).ScriptBlock
}
function Get-HeaderSize {
    param(
        $URL,
        $FileName = "file"
    )
    Try {
        $Size = (Invoke-WebRequest -Useb $URL -Method Head -ErrorAction Stop).Headers.'Content-Length'
    }Catch{
        Write-Host "Failed to parse $FileName size (Invalid URL?):" -ForegroundColor DarkRed
        Write-Host $_.Exception.Message -ForegroundColor Red
        return

    }
    return [Math]::Round((($Size | Select-Object -First 1) / 1MB), 2)
    
}
function Get-Path {
    [alias('gpa')]
    param($File)

    if (-Not(Get-Command $File -ErrorAction Ignore)){return $null}

    $BaseName, $Extension = $File.Split('.')

    if (Get-Command "$BaseName.shim" -ErrorAction Ignore){
        return (Get-Content (Get-Command "$BaseName.shim").Source | Select-Object -First 1).Trim('path = ')
    }elseif($Extension){
        return (Get-Command "$BaseName.$Extension").Source
    }else{
        return (Get-Command $BaseName).Source
    }
}

function Get-ScoopApp {
    [CmdletBinding()] param (

        [Parameter(ValueFromRemainingArguments = $true)]
        [System.Collections.Arraylist]
        $Apps # Not necessarily plural
    )

    Install-Scoop

    $Scoop = (Get-Item (Get-Command scoop).Source).Directory | Split-Path
    $ToInstall = $Apps | Where-Object {$PSItem -NotIn (Get-ChildItem "$Scoop\apps")}
    $Available = (Get-ChildItem "$Scoop\buckets\*\bucket\*").BaseName
    $Buckets = (Get-ChildItem "$Scoop\buckets" -Directory).Name
    $script:FailedToInstall = @()

    function Get-Git {
        if ('git' -NotIn $Available){
            scoop install git
            if ($LASTEXITCODE -ne 0){
                Write-Host "Failed to install Git." -ForegroundColor Red
                return
            }
        }
        $ToInstall = $ToInstall | Where-Object {$_ -ne 'git'}
    }

    $Repos = @{

        extras = @{org = 'ScoopInstaller';repo = 'extras';branch = 'master'}
        utils = @{org = 'couleur-tweak-tips';repo = 'utils';branch = 'main'}
        nirsoft = @{org = 'kodybrown';repo = 'scoop-nirsoft';branch = 'master'}
        games = @{org = 'ScoopInstaller';repo = 'games';branch = 'master'}
        'nerd-fonts' = @{org = 'ScoopInstaller';repo = 'nerd-fonts';branch = 'master'}
        versions = @{org = 'ScoopInstaller';repo = 'versions';branch = 'master'}
        java = @{org = 'ScoopInstaller';repo = 'java';branch = 'master'}
    }
    $RepoNames = $Repos.Keys -Split('\r?\n')

    Foreach($App in $ToInstall){

        if ($App.Split('/').Count -eq 2){

            $Bucket, $App = $App.Split('/')

            if ($Bucket -NotIn $RepoNames){
                Write-Host "Bucket $Bucket is not known, add it yourself by typing 'scoop.cmd bucket add bucketname https://bucket.repo/url'"
                continue
            }elseif (($Bucket -NotIn $Buckets) -And ($Bucket -In $RepoNames)){
                Get-Git
                scoop bucket add $Repos.$Bucket.repo https://github.com/$($Repos.$Bucket.org)/$($Repos.$Bucket.repo)
            }
        }

        $Available = (Get-ChildItem "$Scoop\buckets\*\bucket\*").BaseName

        if ($App -NotIn $Available){
            Remove-Variable -Name Found -ErrorAction Ignore
            ForEach($Bucket in $RepoNames){
                if ($Found){continue}

                Write-Host "`rCould not find $App, looking for it in the $Bucket bucket.." -NoNewline

                $Response = Invoke-RestMethod "https://api.github.com/repos/$($Repos.$Bucket.org)/$($Repos.$Bucket.repo)/git/trees//$($Repos.$Bucket.branch)?recursive=1"
                $Manifests = $Response.tree.path | Where-Object {$_ -Like "bucket/*.json"}
                $Manifests = ($Manifests).Replace('bucket/','').Replace('.json','')

                if ($App -in $Manifests){
                    $script:Found = $True
                    ''
                    Get-Git
                    
                    scoop bucket add $Repos.$Bucket.repo https://github.com/$($Repos.$Bucket.org)/$($Repos.$Bucket.repo)
                }else{''} # Fixes the -NoNewLine
            }
            
        }
        scoop install $App
        if ($LASTEXITCODE -ne 0){
            $script:FailedToInstall += $App
            Write-Verbose "$App exitted with code $LASTEXITCODE"        
        }
    }

}
function Get-ShortcutTarget {
    [alias('gst')]

    param([String]$ShortcutPath)

    Try {
        $null = Get-Item $ShortcutPath -ErrorAction Stop
    } Catch {
        throw
    }
    
    return (New-Object -ComObject WScript.Shell).CreateShortcut($ShortcutPath).TargetPath
}
function Get-TLShell {
    param([switch]$Profile)

if ($Profile){
    

}else{

    $WR = "$env:LOCALAPPDATA\Microsoft\WindowsApps" # I've had the habit of calling this folder WR
                                                    # because it's the only folder I know that is added to path
                                                    # that you don't need perms to access.

    if ($WR -NotIn $env:PATH.Split(';')){
        Write-Error "`"$env:LOCALAPPDATA\Microsoft\WindowsApps`" is not added to path, did you mess with Windows?"
        return
    }else{
        Set-Content "$WR\TL.CMD" @"
@echo off
title TweakList Shell
fltmc >nul 2>&1 || (
    echo Elevating to admin..
    PowerShell Start-Process -Verb RunAs '%0' 2> nul || (
        echo Failed to elevate to admin, launch CMD as Admin and type in "TL"
        pause & exit 1
    )
    exit 0
)
cd "$HOME"

where.exe pwsh.exe
if "%ERRORLEVEL%"=="1" (set sh=pwsh.exe) else (set sh=powershell.exe)
%SH% -ep bypass -nologo -noexit -command [System.Net.ServicePointManager]::SecurityProtocol='Tls12';iex(irm https://github.com/couleur-tweak-tips/TweakList/releases/latest/download/Master.ps1)
"@ -Force
    }
}
}
function Install-FFmpeg {

    Install-Scoop

    Set-ExecutionPolicy Bypass -Scope Process -Force

    [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'

    $IsFFmpegScoop = (Get-Command ffmpeg -Ea Ignore).Source -Like "*\shims\*"

    if(Get-Command ffmpeg -Ea Ignore){

        $IsFFmpeg5 = (ffmpeg -hide_banner -h filter=libplacebo)

        if (-Not($IsFFmpeg5)){

            if ($IsFFmpegScoop){
                scoop update ffmpeg
            }else{
                Write-Warning @"
An FFmpeg installation was detected, but it is not version 5.0 or higher.
If you installed FFmpeg yourself, you can remove it and use the following command to install ffmpeg and add it to the path:
scoop install ffmpeg
"@
                
            }
            
        }
                
    }else{

        $Local = ((scoop cat ffmpeg) | ConvertFrom-Json).version
        $Latest = (Invoke-RestMethod https://raw.githubusercontent.com/ScoopInstaller/Main/master/bucket/ffmpeg.json).version

        if ($Local -ne $Latest){
            "FFmpeg version installed using scoop is outdated, updating Scoop.."
            if (-not(Get-Command git -Ea Ignore)){
                scoop install git
            }
            scoop update
        }

        scoop install ffmpeg
    }
}
function Install-Scoop {
    param(
        [String]$InstallDir
    )
    Set-ExecutionPolicy Bypass -Scope Process -Force

    if (-Not(Get-Command scoop -Ea Ignore)){
        
        $RunningAsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')

        if($InstallDir){
            $env:SCOOP = $InstallDir	
            [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
        }

        If (-Not($RunningAsAdmin)){
            Invoke-Expression (Invoke-RestMethod -Uri http://get.scoop.sh)
        }else{
            Invoke-Expression "& {$(Invoke-RestMethod -Uri https://get.scoop.sh)} -RunAsAdmin"
        }
    }

    Try {
        scoop -ErrorAction Stop | Out-Null
    } Catch {
        Write-Warning "Something went wrong with installing Scoop"
        ''
        Write-Host $PSItem -ForegroundColor Red
        ''
        Pause
        exit
    }
}
<# Here's some example hashtables you can mess with:

$Original = @{ # Original settings
    potato = $true
    avocado = $false
}

$Patch = @{ # Fixes
    avocado = $true
}

#>
function Merge-Hashtables {
    param(
        [Switch]$ShowDiff,
        [HashTable]$Original,
        [HashTable]$Patch
    )

    $Merged = @{} # Final Merged settings

    foreach($Key in $Original.Keys){ # Loops through all OG settings

        if ($Patch.$Key){ # If the setting exists in the new settings
            $Merged += @{$Key = $Patch.$Key} # Then add it to the final settings
        }else{ # Else put in the normal settings
            $Merged += @{$Key = $Original.$Key}
        }
    }
    return $Merged
}
function PauseNul {
    $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}
function Restart-ToBIOS {
    
    Remove-Variable -Name Choice -Ea Ignore

    while ($Choice -NotIn 'y','yes','n','no'){
        $Choice = Read-Host "Restart to BIOS? (Y/N)"
    }

    if ($Choice -in 'y','yes'){
        shutdown /fw /r /t 0
    }
    
}
function Set-Choice ($Letters){ # Convenient function for choice.exe
    if (-Not(Test-Path "$env:windir\system32\choice.exe")){Write-Error 'Choice.exe is not present on your machine';pause;exit}
    choice.exe /C $Letters /N | Out-Null
    return $Letters[$($LASTEXITCODE - 1)]
}
function Set-Title ($Title) {
    Invoke-Expression "$Host.UI.RawUI.WindowTitle = `"TweakList - `$(`$MyInvocation.MyCommand.Name) [$Title]`""
}
function Set-Verbosity {
    [alias('Verbose')]
    param (

		[Parameter(Mandatory = $true,ParameterSetName = "Enabled")]
        [switch]$Enabled,

		[Parameter(Mandatory = $true,ParameterSetName = "Disabled")]
		[switch]$Disabled
	)
    
    switch ($PSCmdlet.ParameterSetName){
        "Enabled" {
            $script:Verbose = $True
            $script:VerbosePreference = 'Continue'
        }
        "Disabled" {
            $script:Verbose = $True
            $script:VerbosePreference = 'SilentlyContinue'
        }
    }
}
function CB-CleanTaskbar {
	Invoke-Expression (Import-Sophia)
	CortanaButton -Hide
	PeopleTaskbar -Hide
	TaskBarSearch -Hide
	TaskViewButton -Hide
	UnpinTaskbarShortcuts Edge, Store, Mail
}
<#

List of commonly used Appx packages:

Windows.PrintDialog
Microsoft.WindowsCalculator
Microsoft.ZuneVideo
Microsoft.Windows.Photos

I did not add them, but you can opt in by calling the function, e.g:

    Remove-KnownAppxPackages -Add @('Windows.PrintDialog','Microsoft.WindowsCalculator')

Don't forget to surround them by a ' so PowerShell considers them as a string

#>

function Remove-KnownAppxPackages ([array]$Add,[array]$Exclude) {

    $AppxPackages = @(
        "Microsoft.Windows.NarratorQuickStart"
        "Microsoft.Wallet"
        "3DBuilder"
        "Microsoft.Microsoft3DViewer"
        "WindowsAlarms"
        "BingSports"
        "WindowsCommunicationsapps"
        "WindowsCamera"
        "Feedback"
        "Microsoft.GetHelp"
        "GetStarted"
        "ZuneMusic"
        "WindowsMaps"
        "Microsoft.Messaging"
        "Microsoft.MixedReality.Portal"
        "Microsoft.OneConnect"
        "BingFinance"
        "Microsoft.MSPaint"
        "People"
        "WindowsPhone"
        "Microsoft.YourPhone"
        "Microsoft.Print3D"
        "Microsoft.ScreenSketch"
        "Microsoft.MicrosoftStickyNotes"
        "SoundRecorder"
        
        ) | Where-Object { $_ -notin $Exclude }

        $AppxPackages += $Add # Appends the Appx packages given by the user (if any)

        if (-Not($KeepXboxPackages)){
            $AppxPackages += @(
                "XboxApp"
                "Microsoft.XboxGameOverlay"
                "Microsoft.XboxGamingOverlay"
                "Microsoft.XboxSpeechToTextOverlay"
                "Microsoft.XboxIdentityProvider"
                "Microsoft.XboxGameCallableUI"
            )
        }


        ForEach ($Package in $AppxPackages){
        
        if ($PSVersionTable.PSEdition -eq 'Core'){ # Newer PowerShell versions don't have Appx cmdlets, manually calling PowerShell to 
        
            powershell.exe -command "Get-AppxPackage `"*$Package*`" | Remove-AppxPackage"
        
        }else{
            Get-AppxPackage "*$Package*" | Remove-AppxPackage
        }
        
        }

}

function Remove-UselessFiles {
    
    @(
        "$env:TEMP"
        "$env:WINDIR\TEMP"
        "$env:HOMEDRIVE\TEMP"
    ) | ForEach-Object { Remove-Item (Convert-Path $_\*) -Force -ErrorAction SilentlyContinue }

}
function Set-PowerPlan {
    param (
        [string]$URL,
        [switch]$Ultimate
        )

    if ($Ultimate){
        powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
    }elseif($PowURL){
        $DotPow = "$env:TMP\Powerplan $(Get-Random).pow"
        Invoke-WebRequest -Uri $PowURL -OutFile $DotPow
        powercfg -duplicatescheme $DotPow
        powercfg /s $DotPow
    }
}
function Set-Win32ProritySeparation ([int]$DWord){

    $Path = 'REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl'
    $current = (Get-ItemProperty $Path).Win32PrioritySeparation

    Set-ItemProperty -Path ($Path).Win32PrioritySeparation -Value $Value -Type DWord -Force -ErrorAction Inquire

    Write-Verbose "Set-Win32ProritySeparation: Changed from $current to $((Get-ItemProperty $Path).Win32PrioritySeparation)"

}

function Check-XMP {
    Write-Host "Checking RAM.." -NoNewline
    $PhysicalMemory = Get-CimInstance -ClassName Win32_PhysicalMemory
    $RamSpeed = $PhysicalMemory.Speed | Select-Object -First 1 # In MHz
    $IsDesktop = $null -eq (Get-CimInstance -ClassName Win32_Battery) # No battery = not a laptop (in some very rare cases that may fail but whatever it's accurate enough)
    $IsDDR4 = ($PhysicalMemory.SMBIOSMemoryType | Select-Object -First 1) -eq 26 # DDR4 = 26, DDR3 = 24
    switch((Get-CimInstance -ClassName CIM_Processor).Manufacturer){
        {$PSItem -Like "*AMD*" -or $PSItem -Like "*Advanced Micro*"}{$RamOCType = 'DOCP'}
        default{$RamOCType = 'XMP'} # Whatever else it is, it's preferably XMP
    }
    if (($RamSpeed -eq 2133) -and $IsDesktop -and $IsDDR4){
        Write-Output @"
`rYour RAM is running at the default DDR4 RAM speed of 2133 MHz.
Check if your RAM allows running at a higher speed, and if yes, turn on $RamOCType in the BIOS
"@
    }else{
        Write-Output "`rCould not determine the need for XMP/DOCP"
    }
    if ($RamSpeed){"- Your RAM speed is $RamSpeed MHz"}
    if ($null -ne $IsDesktop){"- You're on a desktop: $IsDesktop"}
    if ($null -ne $IsDDR4){"- Your RAM is DDR4: $IsDDR4"}
}

# Completely inspired from Felipe: dsc.gg/Felipe
# Reference video: https://www.youtube.com/watch?v=hJfxTXYpSLI
function Get-AMDDriver {
    [alias('gamd')]
    param(
        [String]$DriverFilePath
    )

    if (-Not($DriverFilePath)){
        Write-Host @"
AMD does not allow automatic downloads,
go on https://www.amd.com/support and download a driver FROM THE LIST, not the automatic detection one

You can then call this function again with the -DriverFilePath parameter, example:

Get-AMDDriver -DriverFilePath 'C:\Users\$env:USERNAME\Downloads\amd-software-adrenalin-edition-22.4.1-win10-win11-april5.exe'
"@ -ForegroundColor Red
return
    }

    Try {
        Test-Path $DriverFilePath -PathType Leaf -ErrorAction Stop | Out-Null
    } Catch {
        "The driver file $DriverFilePath does not exist"
        exit 1
    }

    $7z = Get-7zPath
    $Folder = "$env:TMP\AMD Driver - $(Get-Random)"

    Invoke-Expression "& `"$7z`" x -bso0 -bsp1 -bse1 -aoa `"$DriverFilePath`" -o`"$Folder`""

    Remove-Item "$Folder\Packages\Drivers\Display\WT6A_INF\amd*"

    $DLLsDir = Resolve-Path "$Folder\Packages\Drivers\Display\WT*_INF\B*"

    $ToStrip = [Ordered]@{
        'ccc2_install.exe' = 'ccc2_install.exe=1'
        'atiesrxx.exe' = 'atiesrxx.exe'
        'amdlogum.exe' = 'amdlogum.exe,,,0x00004000', 'amdlogum.exe=1'
        'dgtrayicon.exe' = 'dgtrayicon.exe,,,0x00004000', 'dgtrayicon.exe=1'
        'GameManager64.dll' = 'GameManager64.dll,,,0x00004000', 'gamemanager64.dll=1'
        'amdlvr64.dll' = 'amdlvr64.dll,,,0x00004000', 'amdlvr64.dll=1'
        'RapidFireServer64.dll' = 'RapidFireServer64.dll,,,0x00004000', 'rapidfireserver64.dll=1'
        'Rapidfire64.dll' = 'Rapidfire64.dll,,,0x00004000', 'rapidfire64.dll=1'
        'atieclxx.exe' = 'atieclxx.exe,,,0x00004000', 'atieclxx.exe=1'
        'branding.bmp' = 'branding.bmp,,,0x00004000', 'branding.bmp=1'
        'brandingRSX.bmp' = 'brandingRSX.bmp,,,0x00004000','brandingrsx.bmp=1'
        'brandingWS_RSX.bmp' = 'brandingWS_RSX.bmp,,,0x00004000', 'brandingws_rsx.bmp=1'
        'GameManager32.dll' = 'GameManager32.dll,,,0x00004000', 'gamemanager32.dll=1'
        'amdlvr32.dll' = 'amdlvr32.dll,,,0x00004000', 'amdlvr32.dll=1'
        'RapidFireServer.dll' = 'RapidFireServer.dll,,,0x00004000', 'rapidfireserver.dll=1'
        'Rapidfire.dll' = 'Rapidfire.dll,,,0x00004000', 'rapidfire.dll=1'
        'amdfendr.ctz' = 'amdfendr.ctz=1'
        'amdfendr.itz' = 'amdfendr.itz=1'
        'amdfendr.stz' = 'amdfendr.stz=1'
        'amdfendrmgr.stz' = 'amdfendrmgr.stz=1'
        'amdfendrsr.etz' = 'amdfendrsr.etz=1'
        'atiesrxx.ex' = 'atiesrxx.exe=1'

        'amdmiracast.dll' = 'amdmiracast.dll,,,0x00004000', 
                            'HKR,,ContentProtectionDriverName,%REG_SZ%,amdmiracast.dll', 
                            'amdmiracast.dll=1', 
                            'amdmiracast.dll=SignatureAttributes.PETrust'

        CopyINFs = 'CopyINF = .\amdxe\amdxe.inf', 
                   'CopyINF = .\amdfendr\amdfendr.inf', 
                   'CopyINF = .\amdafd\amdafd.inf'
    }
    Remove-Item (Get-ChildItem $DLLsDir -Force | Where-Object {$_.Name -in $ToStrip.Keys}) -Force -ErrorAction Ignore

    $inf = Resolve-Path "$DLLsDir\..\U*.inf"

    (Get-Content $inf ) | Where-Object {$_ -NotIn $ToStrip.Values} | Set-Content $inf -Force

}
function Get-GraalVM {
    param(
        [Switch]$Reinstall
    )

    if ((Test-Path "$env:ProgramData\GraalVM") -and !$Reinstall){
        "GraalVM is already installed, run with -Reinstall to force reinstallation"
    }
    if (-Not(Get-Command curl.exe -ErrorAction Ignore)){
        return "curl is not found (comes with windows per default?)"
    }
    Remove-Item "$env:ProgramData\GraalVM" -ErrorAction Ignore -Force -Recurse

    $URL = 'https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-21.2.0/graalvm-ce-java16-windows-amd64-21.2.0.zip'
    $SHA256 = 'DAE2511ABFF8EAD3EBC90CD9FC81A8E84B762FC91462B198C3EDDF28F81A937E'
    $Zip =  "$env:TMP\GraalVM.zip"


    if (-Not(Test-Path $Zip)){
        Write-Host "Downloading GraalVM ($(Get-HeaderSize $URL)`MB).." -ForegroundColor Green
        curl.exe -# -L $URL -o"$Zip"
    }

    if ((Get-FileHash $Zip).Hash -ne $SHA256){
        return "Failed to download GraalVM (SHA256 checksum mismatch, not the expected file)"

    }
    if (Get-Command 7z -ErrorAction Ignore){
        Invoke-Expression "& `"7z`" x -bso0 -bsp1 -bse1 -aoa `"$env:TMP\GraalVM.zip`" -o`"$env:ProgramData\GraalVM`""
    } else {
        Expand-Archive -Path $Zip -Destination "$env:ProgramData\GraalVM"
    }
    Move-Item -Path "$env:ProgramData\GraalVM\graalvm-?e*\*" "C:\ProgramData\GraalVM"
}
# Made by Aetopia, rewrote by Couleur

function Get-NVIDIADriver {
    [alias('gnvd')]
    param(
        [String]$DriverLink, # Use your own driver link, it must be direct (no google drive)
        [Switch]$Minimal,    # If you want to use 7-Zip to extract and strip the driver
        [Switch]$GetLink,    # Returns the download link
        [Switch]$OpenLink    # Opens the download link in your default browser
    )

    if (-Not($DriverLink)){

        $File = Invoke-RestMethod 'https://www.nvidia.com/Download/processFind.aspx?psid=101&pfid=845&osid=57&lid=1&whql=1&ctk=0&dtcid=1'
        $GameReadyVersions = @()
        foreach ($Line in $File.Split('`n')){
            if ($Line -match "<td class=""gridItem"">*.*</td>") {
                $Version = $Line.Split('>')[5].Split('<')[0]
                $GameReadyVersions += $Version 
            }
        }
        $Version = $GameReadyVersions | Select-Object -First 1
    
        $DriverFile = "$env:TEMP\NVIDIA Driver - Game Ready - $Version.exe"
    
        $DriverLink = "https://international.download.nvidia.com/Windows/$Version/$Version-desktop-win10-win11-64bit-international-dch-whql.exe"
    
    }elseif($DriverLink){

        $DriverFile = "$env:TEMP\NVIDIA Driver - (Custom DL Link).exe"
    }

    # If any of these two args are used this function is simply a NVIDIA driver link parser
    if ($GetLink){return $DriverLink}
    elseif($OpenLink){Start-Process $DriverLink;return}

    Try {
        $DriverSize = (Invoke-WebRequest -Useb $DriverLink -Method Head).Headers.'Content-Length'
    } Catch {
        Write-Host "Failed to parse driver size (Invalid URL?):" -ForegroundColor DarkRed
        Write-Host $_.Exception.Message -ForegroundColor Red
        return
    }
    $DriverSize = [int]($DriverSize/1MB)
    Write-Host "Downloading NVIDIA Driver $Version ($DriverSize`MB)..." -ForegroundColor Green

    curl.exe -L -# $DriverLink -o $DriverFile

    if ($Minimal){

        $Components = @(
            "Display.Driver"
            "NVI2"
            "EULA.txt"
            "ListDevices.txt"
            "GFExperience/*.txt"
            "GFExperience/locales"
            "GFExperience/EULA.html"
            "GFExperience/PrivacyPolicy"
            "setup.cfg"
            "setup.exe"
        )
        
        $7z = Get-7zPath

        Write-Outp "Unpacking driver package with minimal components..."
        $Folder = "$env:TEMP\7z-$(Get-Item $DriverFile | Select-Object -ExpandProperty BaseName)"
        Invoke-Expression "& `"$7z`" x -bso0 -bsp1 -bse1 -aoa `"$DriverFile`" $Components -o`"$Folder`""
        Get-ChildItem $Folder -Exclude $Components | Remove-Item -Force -Recurse
        
        $CFG = Get-Item (Join-Path $Folder setup.cfg)
        $XML = @(
            '		<file name="${{EulaHtmlFile}}"/>'
            '		<file name="${{FunctionalConsentFile}}"/>'
            '		<file name="${{PrivacyPolicyFile}}"/>'
        )
        (Get-Content $CFG) | Where-Object {$_ -NotIn $XML} | Set-Content $CFG

        $setup = Join-Path $Folder setup.exe
    }else{
        $setup = $DriverFile
    }

    Write-Host "Launching the installer, press any key to continue and accept the UAC"
    Write-Verbose $setup
    PauseNul
    Start-Process $setup -Verb RunAs

}
# This function centralizes most of what you can download/install on CTT
# Anything it doesn't find in that switch ($App){ statement is passed to scoop
 
function Get {
    [alias('g')] # minimalism at it's finest
    param(
        [Array]$Apps
    )

    $FailedToInstall = $null # Reset that variable for later

    ForEach($App in $Apps){ # Scoop exits when it throws

        switch ($App){
            #'Voukoder'{} soonTMTM
            'Upscaler'{
                Install-FFmpeg
                Invoke-RestMethod 'https://github.com/couleur-tweak-tips/utils/raw/main/Miscellaneous/CTT%20Upscaler.cmd' |
                Out-File (Join-Path ([System.Environment]::GetFolderPath('SendTo')) 'CTT Upscaler.cmd') -Encoding ASCII -Force
                Write-Host @"
CTT Upscaler has been installed,
I strongly recommend you open settings to tune it to your PC, there's lots of cool stuff to do there!
"@ -ForegroundColor Green
            }
            'Scoop'{Install-Scoop}
            'FFmpeg'{Install-FFmpeg}
            {$_ -In '7-Zip','7z','7Zip'}{Get-ScoopApp 7zip}
            {$_ -In 'Smoothie','sm'}{Install-FFmpeg;Get-ScoopApp utils/Smoothie}
            {$_ -In 'UTVideo'}{Get-ScoopApp utils/utvideo}
            {$_ -In 'Nmkoder'}{Get-ScoopApp utils/nmkoder}
            {$_ -In 'Librewolf'}{Get-ScoopApp extras/librewolf}
            {$_ -In 'ffmpeg-nightly'}{Get-ScoopApp versions/ffmpeg-nightly}
            {$_ -In 'Graal','GraalVM'}{Get-ScoopApp utils/GraalVM}
            {$_ -In 'DiscordCompressor','dc'}{Get-ScoopApp utils/discordcompressor}
            {$_ -In 'Moony','mn'}{if (-Not(Test-Path "$HOME\.lunarclient")){Write-Warning "You NEED Lunar Client to launch it with Moony"};Get-ScoopApp utils/Moony}
            {$_ -In 'TLShell','TLS'}{Get-TLShell}
            default{Get-ScoopApp $App}
        }

    }
    if ($FailedToInstall){
        
        Write-Host "[!] The following apps failed to install (scroll up for details):" -ForegroundColor Red
        $FailedToInstall
    }
}
<#
    .SYNOPSIS
    Scraps the latest version of Sophia edition weither you have W10/11/LTSC/PS7, changes all function scopes and invokes it, as if it were importing it as a module

    You can find farag's dobonhonkerosly big Sophia Script at https://github.com/farag2/Sophia-Script-for-Windows
    And if you'd like using it as a GUI, try out SophiApp:  https://github.com/Sophia-Community/SophiApp
    
    .EXAMPLE
    Import-Sophia
    # Or for short:
    ipso
#>
function Import-Sophia {
    [alias('ipso')]
    param()

    $SophiaVer = "Sophia Script for " # This will get appended later on
    $PSVer = $PSVersionTable.PSVersion.Major

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # doesn't hurt ))

    if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName) -eq "Windows 10 Enterprise LTSC 2021")
    {
        $SophiaVer += "Windows 10 LTSC 2021 PowerShell $PSVer"
    }
        elseif ((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber -eq 17763)
    {
        $SophiaVer += "Windows 10 LTSC 2019 PowerShell $PSVer"
    }
        else
    {
        $SophiaVer += "Windows $([System.Environment]::OSVersion.Version.Major)"
        if ($PSVer -ge 7){$SophiaVer += " PowerShell $PSVer"}
    }

    $RawURL = "https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/master/Sophia%20Script/$($SophiaVer -Replace ' ','%20')/Module/Sophia.psm1"
    Write-Verbose $RawURL

    $SophiaFunctions = (Invoke-RestMethod $RawURL -ErrorAction Stop)

    While ($SophiaFunctions[0] -ne '<'){
        $SophiaFunctions = $SophiaFunctions.Substring(1) # BOM ((
    } 

    $SophiaFunctions = $SophiaFunctions -replace 'RestartFunction','tempchannge' # farag please forgive me
    $SophiaFunctions = $SophiaFunctions -replace 'function ','function global:'
    $SophiaFunctions = $SophiaFunctions -replace 'tempchange','RestartFunction'
    Invoke-Expression $SophiaFunctions
}
function Set-CompatibilitySettings {
    [alias('scs')]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Path,

        [Switch]$DisableFullScreenOptimizations,
        [Switch]$RunAsAdmin
    )

    if (!$RunAsAdmin -and !$DisableFullScreenOptimizations){
        return "No compatibility settings were set, returning."
    }

    if ($FilePath.Extension -eq '.lnk'){
        $FilePath = Get-Item (Get-ShortcutTarget $FilePath) -ErrorAction Stop
    }else{
        $FilePath = Get-Item $Path -ErrorAction Stop
    }

    $Data = '~'
    if ($DisableFullScreenOptimizations){$Data += " DISABLEDXMAXIMIZEDWINDOWEDMODE"}
    if ($RunAsAdmin){$Data += " RUNASADMIN"}

    New-ItemProperty -Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" `
    -Name $FilePath.FullName -PropertyType String -Value $Data -Force | Out-Null

}
# Default is 400(ms)
function Set-MenuShowDelay {
    param(
        [Int]$DelayInMs
    )
    
    Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" -Name MenuShowDelay -PropertyType String -Value $DelayInMs -Force
}
