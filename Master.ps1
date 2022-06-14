# This file is automatically built at every commit to add up every function to a single file, this makes it simplier to parse (aka download) and execute.

using namespace System.Management.Automation # Needed by Invoke-NGENposh
$CommitCount = 125
$FuncsCount = 48
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
    $Response = Read-Host $Message
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
        [String]$Resolution = '3840x2160',
        [Switch]$Silent,
        [Switch]$EzEncArgs
    )

Install-FFmpeg

$DriverVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}_Display.Driver" -ErrorAction Ignore).DisplayVersion
    if ($DriverVersion){ # Only triggers if it parsed a NVIDIA driver version, else it can probably be an NVIDIA GPU
        if ($DriverVersion -lt 477.41){ # Oldest NVIDIA version capable
        Write-Warning "Outdated NVIDIA Drivers detected ($DriverVersion), you won't be able to encode using NVENC util you update them."
    }
}

$EncCommands = [ordered]@{
    'HEVC NVENC' = 'hevc_nvenc -rc vbr  -preset p7 -b:v 400M -cq 19'
    'H264 NVENC' = 'h264_nvenc -rc vbr  -preset p7 -b:v 400M -cq 16'
    'HEVC AMF' = 'hevc_amf -quality quality -qp_i 16 -qp_p 18 -qp_b 20'
    'H264 AMF' = 'h264_amf -quality quality -qp_i 12 -qp_p 12 -qp_b 12'
    'HEVC QSV' = 'hevc_qsv -preset veryslow -global_quality:v 18'
    'H264 QSV' = 'h264_qsv -preset veryslow -global_quality:v 15'
    'H264 CPU' = 'libx264 -preset slow -crf 16 -x265-params aq-mode=3'
    'HEVC CPU' = 'libx265 -preset medium -crf 18 -x265-params aq-mode=3:no-sao=1:frame-threads=1'
}

$EncCommands.Keys | ForEach-Object -Begin {
    $script:shouldStop = $false
} -Process {
    if ($shouldStop -eq $true) { return }
    Invoke-Expression "ffmpeg.exe -loglevel fatal -f lavfi -i nullsrc=$Resolution -t 0.1 -c:v $($EncCommands.$_) -f null NUL"
    if ($LASTEXITCODE -eq 0){
        $script:valid_args = $EncCommands.$_
        $script:valid_ezenc = $_

        if ($Silent){
            Write-Host ("Found compatible encoding settings using $PSItem`: {0}" -f ($EncCommands.$_)) -ForegroundColor Green
        }
        $shouldStop = $true # Crappy way to stop the loop since most people that'll execute this will technically be parsing the raw URL as a scriptblock
    }
}

if (-Not($script:valid_args)){
    Write-Host "No compatible encoding settings found (should not happen, is FFmpeg installed?)" -ForegroundColor DarkRed
    Get-Command FFmpeg -Ea Ignore
    pause
    return
}

if ($EzEncArgs){
    return $script:valid_ezenc
}else{
    return $valid_args
}

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
        return (Get-Content (Get-Command "$BaseName.shim").Source | Select-Object -First 1).Trim('path = ').replace('"','')
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
    $Installed = (Get-ChildItem "$Scoop\apps" -Directory).Name
    $script:FailedToInstall = @()

    function Get-Git {
        if ('git' -NotIn $Installed){
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
function HEVCCheck {

    if ((cmd /c .mp4) -eq '.mp4=WMP11.AssocFile.MP4'){ # If default video player for .mp4 is Movies & TV
        
        if(Test-Path "Registry::HKEY_CLASSES_ROOT\ms-windows-store"){
            "Opening HEVC extension in Windows Store.."
            Start-Process ms-windows-store://pdp/?ProductId=9n4wgh0z6vhq
        }
    }
}
function Install-FFmpeg {

    Install-Scoop

    Set-ExecutionPolicy Bypass -Scope Process -Force

    [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'

    $IsFFmpegScoop = (Get-Command ffmpeg -Ea Ignore).Source -Like "*\shims\*"

    if(Get-Command ffmpeg -Ea Ignore){

        $IsFFmpeg5 = (ffmpeg -hide_banner -h filter=libplacebo) -ne "Unknown filter 'libplacebo'."

        if (-Not($IsFFmpeg5)){

            if ($IsFFmpegScoop){
                scoop update ffmpeg
            }else{
                Write-Warning @"
An FFmpeg installation was detected, but libplacebo filter could not be found (old FFmpeg version?).
If you installed FFmpeg yourself, you can remove it and use the following command to install ffmpeg and add it to the path:
scoop.cmd install ffmpeg
"@
pause
                
            }
            
        }
                
    }else{

        $Scoop = (Get-Command Scoop.ps1).Source | Split-Path | Split-Path

        if (-Not(Test-Path "$Scoop\buckets\main")){
            if (-Not(Test-Path "$Scoop\apps\git\current\bin\git.exe")){
                scoop install git
            }
            scoop bucket add main
        }

        $Local = ((scoop cat ffmpeg) | ConvertFrom-Json).version
        $Latest = (Invoke-RestMethod https://raw.githubusercontent.com/ScoopInstaller/Main/master/bucket/ffmpeg.json).version

        if ($Local -ne $Latest){
            "FFmpeg version installed using scoop is outdated, updating Scoop.."
            if (-not(Test-Path "$Scoop\apps\git")){
                scoop install git
            }
            scoop update
        }

        scoop install ffmpeg
        if ($LASTEXITCODE -ne 0){
            Write-Warning "Failed to install FFmpeg"
            pause
        }
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
        Write-Host "Failed to install Scoop" -ForegroundColor DarkRed
        Write-Host $_.Exception.Message -ForegroundColor Red
        return

    }
}
#using namespace System.Management.Automation # this can't be a function but whatever, it doesn't slow down anything
# Author:	Collin Chaffin
# License: MIT (https://github.com/CollinChaffin/psNGENposh/blob/master/LICENSE)
function Invoke-NGENposh {
<#
	.SYNOPSIS
		This Powershell function performs various SYNCHRONOUS ngen functions
	
	.DESCRIPTION
		This Powershell function performs various SYNCHRONOUS ngen functions
	
		Since the purpose of this module is to for interactive use,
		I intentionally did not include any "Queue" options.
	
	.PARAMETER All
		Regenerate cache for all system assemblies
	
	.PARAMETER Force
		Invoke ngen on currently loaded assembles (ensure up to date even if cached)
	
	.EXAMPLE
		To invoke ngen on currently loaded assembles, skipping those already generated:

		PS C:\> Invoke-NGENposh
	
	.EXAMPLE	
		To invoke ngen on currently loaded assembles (ensure up to date even if cached):

		PS C:\> Invoke-NGENposh -Force
	
	.EXAMPLE	
		To invoke ngen to regenerate cache for all system assemblies (*SEE WARNING BELOW**):

		PS C:\> Invoke-NGENposh -All
	
	.NOTES
		 **WARNING: The '-All' switch since the execution is SYNCHRONOUS will
					take considerable time, and literally regenerate all the
					global assembly cache.  There should theoretically be no
					downside to this, but bear in mind other than time (and cpu)
					that since all the generated cache files are new, any
					system backups will consider those files as new and may
					likely cause your next incremental backup to be much larger
#>
	param
	(
		[switch]$All,
		[switch]$Force,
		[switch]$Confirm
	)

	if (!$Confirm){
		Write-Host "Press enter to continue and start using NGENPosh, or press CTRL+C to cancel"
		pause
	}
    
# INTERNAL HELPER
function Write-InfoInColor
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$Message,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.ConsoleColor[]]$Background = $Host.UI.RawUI.BackgroundColor,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.ConsoleColor[]]$Foreground = $Host.UI.RawUI.ForegroundColor,
		[Switch]$NoNewline
	)
	
	[HostInformationMessage]$outMessage = @{
		Message			     = $Message
		ForegroundColor	     = $Foreground
		BackgroundColor	     = $Background
		NoNewline		     = $NoNewline
	}
	Write-Information $outMessage -InformationAction Continue
}
	
	Write-InfoInColor "`n===================================================================================" -Foreground 'DarkCyan'
	Write-InfoInColor "                             BEGINNING TO NGEN                                     " -Foreground 'Cyan'
	Write-InfoInColor "===================================================================================`n" -Foreground 'DarkCyan'
	
	Set-Alias ngenpsh (Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) ngen.exe) -Force
	
	if ($All)
	{
		Write-InfoInColor "EXECUTING GLOBAL NGEN`n`n" -Foreground 'Cyan'
		ngenpsh update /nologo /force
	}
	else
	{
		Write-InfoInColor "EXECUTING TARGETED NGEN`n`n" -Foreground 'Cyan'
		
		[AppDomain]::CurrentDomain.GetAssemblies() |
		ForEach-Object {
			if ($_.Location)
			{
				$Name = (Split-Path $_.location -leaf)
				if ((!($Force)) -and [System.Runtime.InteropServices.RuntimeEnvironment]::FromGlobalAccessCache($_))
				{
					Write-InfoInColor "[SKIPPED]" -Foreground 'Yellow' -NoNewLine
					Write-InfoInColor " :: " -Foreground 'White' -NoNewline
					Write-InfoInColor "[ $Name ]" -Foreground 'Cyan'
					
				}
				else
				{
					
					ngenpsh install $_.location /nologo | ForEach-Object {
						if ($?)
						{
							Write-InfoInColor "[SUCCESS]" -Foreground 'Green' -NoNewLine
							Write-InfoInColor " :: " -Foreground 'White' -NoNewline
							Write-InfoInColor "[ $Name ]" -Foreground 'Cyan'
						}
						else
						{
							Write-InfoInColor "[FAILURE]" -Foreground 'Red' -NoNewLine
							Write-InfoInColor " :: " -Foreground 'White' -NoNewline
							Write-InfoInColor "[ $Name ]" -Foreground 'Cyan'
						}
					}
				}
			}
		}
	}
	Write-InfoInColor "`n===================================================================================" -Foreground 'DarkCyan'
	Write-InfoInColor "                               COMPLETED NGEN                                      " -Foreground 'Cyan'
	Write-InfoInColor "===================================================================================`n" -Foreground 'DarkCyan'
}


# https://github.com/chrisseroka/ps-menu
function Menu {
    param ([array]$menuItems, [switch]$ReturnIndex=$false, [switch]$Multiselect)

function DrawMenu {
    param ($menuItems, $menuPosition, $Multiselect, $selection)
    $l = $menuItems.length
    for ($i = 0; $i -le $l;$i++) {
		if ($menuItems[$i] -ne $null){
			$item = $menuItems[$i]
			if ($Multiselect)
			{
				if ($selection -contains $i){
					$item = '[x] ' + $item
				}
				else {
					$item = '[ ] ' + $item
				}
			}
			if ($i -eq $menuPosition) {
				Write-Host "> $($item)" -ForegroundColor Green
			} else {
				Write-Host "  $($item)"
			}
		}
    }
}

function Toggle-Selection {
	param ($pos, [array]$selection)
	if ($selection -contains $pos){ 
		$result = $selection | where {$_ -ne $pos}
	}
	else {
		$selection += $pos
		$result = $selection
	}
	$result
}

    $vkeycode = 0
    $pos = 0
    $selection = @()
    if ($menuItems.Length -gt 0)
	{
		try {
			[console]::CursorVisible=$false #prevents cursor flickering
			DrawMenu $menuItems $pos $Multiselect $selection
			While ($vkeycode -ne 13 -and $vkeycode -ne 27) {
				$press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
				$vkeycode = $press.virtualkeycode
				If ($vkeycode -eq 38 -or $press.Character -eq 'k') {$pos--}
				If ($vkeycode -eq 40 -or $press.Character -eq 'j') {$pos++}
				If ($vkeycode -eq 36) { $pos = 0 }
				If ($vkeycode -eq 35) { $pos = $menuItems.length - 1 }
				If ($press.Character -eq ' ') { $selection = Toggle-Selection $pos $selection }
				if ($pos -lt 0) {$pos = 0}
				If ($vkeycode -eq 27) {$pos = $null }
				if ($pos -ge $menuItems.length) {$pos = $menuItems.length -1}
				if ($vkeycode -ne 27)
				{
					$startPos = [System.Console]::CursorTop - $menuItems.Length
					[System.Console]::SetCursorPosition(0, $startPos)
					DrawMenu $menuItems $pos $Multiselect $selection
				}
			}
		}
		finally {
			[System.Console]::SetCursorPosition(0, $startPos + $menuItems.Length)
			[console]::CursorVisible = $true
		}
	}
	else {
		$pos = $null
	}

    if ($ReturnIndex -eq $false -and $pos -ne $null)
	{
		if ($Multiselect){
			return $menuItems[$selection]
		}
		else {
			return $menuItems[$pos]
		}
	}
	else 
	{
		if ($Multiselect){
			return $selection
		}
		else {
			return $pos
		}
	}
}

$Original = @{
    lets = 'go'
    Sub = @{
      Foo =  'bar'
      big = 'ya'
    }
    finish = 'fish'
}
$Patch = @{
    lets = 'arrive'
    Sub = @{
      Foo =  'baz'
    }
    finish ='cum'
}

function Merge-Hashtables {
    param(
        $Original,
        $Patch
    )
    $Merged = @{} # Final Merged settings

    if (!$Original){$Original = @{}}

    if ($Original.GetType().Name -in 'PSCustomObject','PSObject'){
        $Temp = [ordered]@{}
        $Original.PSObject.Properties | ForEach-Object { $Temp[$_.Name] = $_.Value }
        $Original = $Temp
        Remove-Variable Temp #fck temp vars
    }

    foreach ($Key in [object[]]$Original.Keys) {

        if ($Original.$Key -is [HashTable]){
            $Merged.$Key += [HashTable](Merge-Hashtables $Original.$Key $Patch.$Key)
            continue
        }

        if ($Patch.$Key -and !$Merged.$Key){ # If the setting exists in the patch
            $Merged.Remove($Key)
            $Merged += @{$Key = $Patch.$Key} # Then add it to the final settings
        }else{ # Else put in the unchanged normal setting
            $Merged += @{$Key = $Original.$Key}
        }
    }

    ForEach ($Key in [object[]]$Patch.Keys) {
        if ($Patch.$Key -is [HashTable] -and ($Key -NotIn $Original.Keys)){
            $Merged.$Key += [HashTable](Merge-Hashtables $Original.$Key $Patch.$Key)
            continue
        }
        if ($Key -NotIn $Original.Keys){
            $Merged.$Key += $Patch.$Key
        }
    }

    return $Merged
}

<# Here's some example hashtables you can mess with:

$Original = [Ordered]@{ # Original settings
    potato = $true
    avocado = $false
}

$Patch = @{ # Fixes
    avocado = $true
}


function Merge-Hashtables {
    param(
        [Switch]$ShowDiff,
        $Original,
        $Patch
    )

    if (!$Original){$Original = @{}}

    if ($Original.GetType().Name -in 'PSCustomObject','PSObject'){
        $Temp = [ordered]@{}
        $Original.PSObject.Properties | ForEach-Object { $Temp[$_.Name] = $_.Value }
        $Original = $Temp
        Remove-Variable Temp #fck temp vars
    }

    $Merged = @{} # Final Merged settings

    foreach($Key in $Original.Keys){ # Loops through all OG settings
        $Merging = $True

        if ($Patch.$Key){ # If the setting exists in the new settings
            $Merged += @{$Key = $Patch.$Key} # Then add it to the final settings
        }else{ # Else put in the normal settings
            $Merged += @{$Key = $Original.$Key}
        }
    }
    foreach($key in $Patch.Keys){ # If Patch has hashtables that Original does not
        if (!$Merged.$key){
            $Merged += @{$key = $Patch.$key}
        }
    }

    if (!$Merging){$Merged = $Patch} # If no settings were merged (empty $Original), completely overwrite
    return $Merged
}

#>
function Optimize{
    [alias('opt')]
    param(
        $Script,
        [Parameter(ValueFromRemainingArguments = $true)]
        [System.Collections.Arraylist]
        $Arguments
    )
    switch ($Script){
        'OBS'{Invoke-Expression "Optimize-OBS $Arguments"}
        {$_ -in 'OF','Minecraft','Mc','OptiFine'}{Invoke-Expression "Optimize-OptiFine $Arguments"}
        #{$_ -in 'LC','LunarClient'}{Optimize-LunarClient $Arguments}
        #{$_ -in 'Apex','AL','ApexLegends'}{Optimize-ApexLegends $Arguments}
    }
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
    [alias('Verbose','Verb')]
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

function Write-Menu {
    <#
        By QuietusPlus on GitHub: https://github.com/QuietusPlus/Write-Menu

        .SYNOPSIS
            Outputs a command-line menu which can be navigated using the keyboard.

        .DESCRIPTION
            Outputs a command-line menu which can be navigated using the keyboard.

            * Automatically creates multiple pages if the entries cannot fit on-screen.
            * Supports nested menus using a combination of hashtables and arrays.
            * No entry / page limitations (apart from device performance).
            * Sort entries using the -Sort parameter.
            * -MultiSelect: Use space to check a selected entry, all checked entries will be invoked / returned upon confirmation.
            * Jump to the top / bottom of the page using the "Home" and "End" keys.
            * "Scrolling" list effect by automatically switching pages when reaching the top/bottom.
            * Nested menu indicator next to entries.
            * Remembers parent menus: Opening three levels of nested menus means you have to press "Esc" three times.

            Controls             Description
            --------             -----------
            Up                   Previous entry
            Down                 Next entry
            Left / PageUp        Previous page
            Right / PageDown     Next page
            Home                 Jump to top
            End                  Jump to bottom
            Space                Check selection (-MultiSelect only)
            Enter                Confirm selection
            Esc / Backspace      Exit / Previous menu

        .EXAMPLE
            PS C:\>$menuReturn = Write-Menu -Title 'Menu Title' -Entries @('Menu Option 1', 'Menu Option 2', 'Menu Option 3', 'Menu Option 4')

            Output:

              Menu Title

               Menu Option 1
               Menu Option 2
               Menu Option 3
               Menu Option 4

        .EXAMPLE
            PS C:\>$menuReturn = Write-Menu -Title 'AppxPackages' -Entries (Get-AppxPackage).Name -Sort

            This example uses Write-Menu to sort and list app packages (Windows Store/Modern Apps) that are installed for the current profile.

        .EXAMPLE
            PS C:\>$menuReturn = Write-Menu -Title 'Advanced Menu' -Sort -Entries @{
                'Command Entry' = '(Get-AppxPackage).Name'
                'Invoke Entry' = '@(Get-AppxPackage).Name'
                'Hashtable Entry' = @{
                    'Array Entry' = "@('Menu Option 1', 'Menu Option 2', 'Menu Option 3', 'Menu Option 4')"
                }
            }

            This example includes all possible entry types:

            Command Entry     Invoke without opening as nested menu (does not contain any prefixes)
            Invoke Entry      Invoke and open as nested menu (contains the "@" prefix)
            Hashtable Entry   Opened as a nested menu
            Array Entry       Opened as a nested menu

        .NOTES
            Write-Menu by QuietusPlus (inspired by "Simple Textbased Powershell Menu" [Michael Albert])

        .LINK
            https://quietusplus.github.io/Write-Menu

        .LINK
            https://github.com/QuietusPlus/Write-Menu
    #>

    [CmdletBinding()]

    <#
        Parameters
    #>

    param(
        # Array or hashtable containing the menu entries
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('InputObject')]
        $Entries,

        # Title shown at the top of the menu.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]
        $Title,

        # Sort entries before they are displayed.
        [Parameter()]
        [switch]
        $Sort,

        # Select multiple menu entries using space, each selected entry will then get invoked (this will disable nested menu's).
        [Parameter()]
        [switch]
        $MultiSelect
    )

    <#
        Configuration
    #>

    # Entry prefix, suffix and padding
    $script:cfgPrefix = ' '
    $script:cfgPadding = 2
    $script:cfgSuffix = ' '
    $script:cfgNested = ' >'

    # Minimum page width
    $script:cfgWidth = 30

    # Hide cursor
    [System.Console]::CursorVisible = $false

    # Save initial colours
    $script:colorForeground = [System.Console]::ForegroundColor
    $script:colorBackground = [System.Console]::BackgroundColor

    <#
        Checks
    #>

    # Check if entries has been passed
    if ($Entries -like $null) {
        Write-Error "Missing -Entries parameter!"
        return
    }

    # Check if host is console
    if ($host.Name -ne 'ConsoleHost') {
        Write-Error "[$($host.Name)] Cannot run inside current host, please use a console window instead!"
        return
    }

    <#
        Set-Color
    #>

    function Set-Color ([switch]$Inverted) {
        switch ($Inverted) {
            $true {
                [System.Console]::ForegroundColor = $colorBackground
                [System.Console]::BackgroundColor = $colorForeground
            }
            Default {
                [System.Console]::ForegroundColor = $colorForeground
                [System.Console]::BackgroundColor = $colorBackground
            }
        }
    }

    <#
        Get-Menu
    #>

    function Get-Menu ($script:inputEntries) {
        # Clear console
        Clear-Host

        # Check if -Title has been provided, if so set window title, otherwise set default.
        if ($Title -notlike $null) {
            #$host.UI.RawUI.WindowTitle = $Title # DISABLED FOR TWEAKLIST
            $script:menuTitle = "$Title"
        } else {
            $script:menuTitle = 'Menu'
        }

        # Set menu height
        $script:pageSize = ($host.UI.RawUI.WindowSize.Height - 5)

        # Convert entries to object
        $script:menuEntries = @()
        switch ($inputEntries.GetType().Name) {
            'String' {
                # Set total entries
                $script:menuEntryTotal = 1
                # Create object
                $script:menuEntries = New-Object PSObject -Property @{
                    Command = ''
                    Name = $inputEntries
                    Selected = $false
                    onConfirm = 'Name'
                }; break
            }
            'Object[]' {
                # Get total entries
                $script:menuEntryTotal = $inputEntries.Length
                # Loop through array
                foreach ($i in 0..$($menuEntryTotal - 1)) {
                    # Create object
                    $script:menuEntries += New-Object PSObject -Property @{
                        Command = ''
                        Name = $($inputEntries)[$i]
                        Selected = $false
                        onConfirm = 'Name'
                    }; $i++
                }; break
            }
            'Hashtable' {
                # Get total entries
                $script:menuEntryTotal = $inputEntries.Count
                # Loop through hashtable
                foreach ($i in 0..($menuEntryTotal - 1)) {
                    # Check if hashtable contains a single entry, copy values directly if true
                    if ($menuEntryTotal -eq 1) {
                        $tempName = $($inputEntries.Keys)
                        $tempCommand = $($inputEntries.Values)
                    } else {
                        $tempName = $($inputEntries.Keys)[$i]
                        $tempCommand = $($inputEntries.Values)[$i]
                    }

                    # Check if command contains nested menu
                    if ($tempCommand.GetType().Name -eq 'Hashtable') {
                        $tempAction = 'Hashtable'
                    } elseif ($tempCommand.Substring(0,1) -eq '@') {
                        $tempAction = 'Invoke'
                    } else {
                        $tempAction = 'Command'
                    }

                    # Create object
                    $script:menuEntries += New-Object PSObject -Property @{
                        Name = $tempName
                        Command = $tempCommand
                        Selected = $false
                        onConfirm = $tempAction
                    }; $i++
                }; break
            }
            Default {
                Write-Error "Type `"$($inputEntries.GetType().Name)`" not supported, please use an array or hashtable."
                exit
            }
        }

        # Sort entries
        if ($Sort -eq $true) {
            $script:menuEntries = $menuEntries | Sort-Object -Property Name
        }

        # Get longest entry
        $script:entryWidth = ($menuEntries.Name | Measure-Object -Maximum -Property Length).Maximum
        # Widen if -MultiSelect is enabled
        if ($MultiSelect) { $script:entryWidth += 4 }
        # Set minimum entry width
        if ($entryWidth -lt $cfgWidth) { $script:entryWidth = $cfgWidth }
        # Set page width
        $script:pageWidth = $cfgPrefix.Length + $cfgPadding + $entryWidth + $cfgPadding + $cfgSuffix.Length

        # Set current + total pages
        $script:pageCurrent = 0
        $script:pageTotal = [math]::Ceiling((($menuEntryTotal - $pageSize) / $pageSize))

        # Insert new line
        [System.Console]::WriteLine("")

        # Save title line location + write title
        $script:lineTitle = [System.Console]::CursorTop
        [System.Console]::WriteLine("  $menuTitle" + "`n")

        # Save first entry line location
        $script:lineTop = [System.Console]::CursorTop
    }

    <#
        Get-Page
    #>

    function Get-Page {
        # Update header if multiple pages
        if ($pageTotal -ne 0) { Update-Header }

        # Clear entries
        for ($i = 0; $i -le $pageSize; $i++) {
            # Overwrite each entry with whitespace
            [System.Console]::WriteLine("".PadRight($pageWidth) + ' ')
        }

        # Move cursor to first entry
        [System.Console]::CursorTop = $lineTop

        # Get index of first entry
        $script:pageEntryFirst = ($pageSize * $pageCurrent)

        # Get amount of entries for last page + fully populated page
        if ($pageCurrent -eq $pageTotal) {
            $script:pageEntryTotal = ($menuEntryTotal - ($pageSize * $pageTotal))
        } else {
            $script:pageEntryTotal = $pageSize
        }

        # Set position within console
        $script:lineSelected = 0

        # Write all page entries
        for ($i = 0; $i -le ($pageEntryTotal - 1); $i++) {
            Write-Entry $i
        }
    }

    <#
        Write-Entry
    #>

    function Write-Entry ([int16]$Index, [switch]$Update) {
        # Check if entry should be highlighted
        switch ($Update) {
            $true { $lineHighlight = $false; break }
            Default { $lineHighlight = ($Index -eq $lineSelected) }
        }

        # Page entry name
        $pageEntry = $menuEntries[($pageEntryFirst + $Index)].Name

        # Prefix checkbox if -MultiSelect is enabled
        if ($MultiSelect) {
            switch ($menuEntries[($pageEntryFirst + $Index)].Selected) {
                $true { $pageEntry = "[X] $pageEntry"; break }
                Default { $pageEntry = "[ ] $pageEntry" }
            }
        }

        # Full width highlight + Nested menu indicator
        switch ($menuEntries[($pageEntryFirst + $Index)].onConfirm -in 'Hashtable', 'Invoke') {
            $true { $pageEntry = "$pageEntry".PadRight($entryWidth) + "$cfgNested"; break }
            Default { $pageEntry = "$pageEntry".PadRight($entryWidth + $cfgNested.Length) }
        }

        # Write new line and add whitespace without inverted colours
        [System.Console]::Write("`r" + $cfgPrefix)
        # Invert colours if selected
        if ($lineHighlight) { Set-Color -Inverted }
        # Write page entry
        [System.Console]::Write("".PadLeft($cfgPadding) + $pageEntry + "".PadRight($cfgPadding))
        # Restore colours if selected
        if ($lineHighlight) { Set-Color }
        # Entry suffix
        [System.Console]::Write($cfgSuffix + "`n")
    }

    <#
        Update-Entry
    #>

    function Update-Entry ([int16]$Index) {
        # Reset current entry
        [System.Console]::CursorTop = ($lineTop + $lineSelected)
        Write-Entry $lineSelected -Update

        # Write updated entry
        $script:lineSelected = $Index
        [System.Console]::CursorTop = ($lineTop + $Index)
        Write-Entry $lineSelected

        # Move cursor to first entry on page
        [System.Console]::CursorTop = $lineTop
    }

    <#
        Update-Header
    #>

    function Update-Header {
        # Set corrected page numbers
        $pCurrent = ($pageCurrent + 1)
        $pTotal = ($pageTotal + 1)

        # Calculate offset
        $pOffset = ($pTotal.ToString()).Length

        # Build string, use offset and padding to right align current page number
        $script:pageNumber = "{0,-$pOffset}{1,0}" -f "$("$pCurrent".PadLeft($pOffset))","/$pTotal"

        # Move cursor to title
        [System.Console]::CursorTop = $lineTitle
        # Move cursor to the right
        [System.Console]::CursorLeft = ($pageWidth - ($pOffset * 2) - 1)
        # Write page indicator
        [System.Console]::WriteLine("$pageNumber")
    }

    <#
        Initialisation
    #>

    # Get menu
    Get-Menu $Entries

    # Get page
    Get-Page

    # Declare hashtable for nested entries
    $menuNested = [ordered]@{}

    <#
        User Input
    #>

    # Loop through user input until valid key has been pressed
    do { $inputLoop = $true

        # Move cursor to first entry and beginning of line
        [System.Console]::CursorTop = $lineTop
        [System.Console]::Write("`r")

        # Get pressed key
        $menuInput = [System.Console]::ReadKey($false)

        # Define selected entry
        $entrySelected = $menuEntries[($pageEntryFirst + $lineSelected)]

        # Check if key has function attached to it
        switch ($menuInput.Key) {
            # Exit / Return
            { $_ -in 'Escape', 'Backspace' } {
                # Return to parent if current menu is nested
                if ($menuNested.Count -ne 0) {
                    $pageCurrent = 0
                    $Title = $($menuNested.GetEnumerator())[$menuNested.Count - 1].Name
                    Get-Menu $($menuNested.GetEnumerator())[$menuNested.Count - 1].Value
                    Get-Page
                    $menuNested.RemoveAt($menuNested.Count - 1) | Out-Null
                # Otherwise exit and return $null
                } else {
                    Clear-Host
                    $inputLoop = $false
                    [System.Console]::CursorVisible = $true
                    return $null
                }; break
            }

            # Next entry
            'DownArrow' {
                if ($lineSelected -lt ($pageEntryTotal - 1)) { # Check if entry isn't last on page
                    Update-Entry ($lineSelected + 1)
                } elseif ($pageCurrent -ne $pageTotal) { # Switch if not on last page
                    $pageCurrent++
                    Get-Page
                }; break
            }

            # Previous entry
            'UpArrow' {
                if ($lineSelected -gt 0) { # Check if entry isn't first on page
                    Update-Entry ($lineSelected - 1)
                } elseif ($pageCurrent -ne 0) { # Switch if not on first page
                    $pageCurrent--
                    Get-Page
                    Update-Entry ($pageEntryTotal - 1)
                }; break
            }

            # Select top entry
            'Home' {
                if ($lineSelected -ne 0) { # Check if top entry isn't already selected
                    Update-Entry 0
                } elseif ($pageCurrent -ne 0) { # Switch if not on first page
                    $pageCurrent--
                    Get-Page
                    Update-Entry ($pageEntryTotal - 1)
                }; break
            }

            # Select bottom entry
            'End' {
                if ($lineSelected -ne ($pageEntryTotal - 1)) { # Check if bottom entry isn't already selected
                    Update-Entry ($pageEntryTotal - 1)
                } elseif ($pageCurrent -ne $pageTotal) { # Switch if not on last page
                    $pageCurrent++
                    Get-Page
                }; break
            }

            # Next page
            { $_ -in 'RightArrow','PageDown' } {
                if ($pageCurrent -lt $pageTotal) { # Check if already on last page
                    $pageCurrent++
                    Get-Page
                }; break
            }

            # Previous page
            { $_ -in 'LeftArrow','PageUp' } { # Check if already on first page
                if ($pageCurrent -gt 0) {
                    $pageCurrent--
                    Get-Page
                }; break
            }

            # Select/check entry if -MultiSelect is enabled
            'Spacebar' {
                if ($MultiSelect) {
                    switch ($entrySelected.Selected) {
                        $true { $entrySelected.Selected = $false }
                        $false { $entrySelected.Selected = $true }
                    }
                    Update-Entry ($lineSelected)
                }; break
            }

            # Select all if -MultiSelect has been enabled
            'Insert' {
                if ($MultiSelect) {
                    $menuEntries | ForEach-Object {
                        $_.Selected = $true
                    }
                    Get-Page
                }; break
            }

            # Select none if -MultiSelect has been enabled
            'Delete' {
                if ($MultiSelect) {
                    $menuEntries | ForEach-Object {
                        $_.Selected = $false
                    }
                    Get-Page
                }; break
            }

            # Confirm selection
            'Enter' {
                # Check if -MultiSelect has been enabled
                if ($MultiSelect) {
                    Clear-Host
                    # Process checked/selected entries
                    $menuEntries | ForEach-Object {
                        # Entry contains command, invoke it
                        if (($_.Selected) -and ($_.Command -notlike $null) -and ($entrySelected.Command.GetType().Name -ne 'Hashtable')) {
                            Invoke-Expression -Command $_.Command
                        # Return name, entry does not contain command
                        } elseif ($_.Selected) {
                            return $_.Name
                        }
                    }
                    # Exit and re-enable cursor
                    $inputLoop = $false
                    [System.Console]::CursorVisible = $true
                    break
                }

                # Use onConfirm to process entry
                switch ($entrySelected.onConfirm) {
                    # Return hashtable as nested menu
                    'Hashtable' {
                        $menuNested.$Title = $inputEntries
                        $Title = $entrySelected.Name
                        Get-Menu $entrySelected.Command
                        Get-Page
                        break
                    }

                    # Invoke attached command and return as nested menu
                    'Invoke' {
                        $menuNested.$Title = $inputEntries
                        $Title = $entrySelected.Name
                        Get-Menu $(Invoke-Expression -Command $entrySelected.Command.Substring(1))
                        Get-Page
                        break
                    }

                    # Invoke attached command and exit
                    'Command' {
                        Clear-Host
                        Invoke-Expression -Command $entrySelected.Command
                        $inputLoop = $false
                        [System.Console]::CursorVisible = $true
                        break
                    }

                    # Return name and exit
                    'Name' {
                        Clear-Host
                        return $entrySelected.Name
                        $inputLoop = $false
                        [System.Console]::CursorVisible = $true
                    }
                }
            }
        }
    } while ($inputLoop)
}
function CB-CleanTaskbar {
	Invoke-Expression (Import-Sophia)
	CortanaButton -Hide
	PeopleTaskbar -Hide
	TaskBarSearch -Hide
	TaskViewButton -Hide
	UnpinTaskbarShortcuts Edge, Store, Mail
}
function Optimize-OBS {
    [alias('optobs')]
    param(
        [Parameter(Mandatory)] # Override encoder check
        [ValidateSet('x264','NVENC','AMF'<#,'QuickSync'#>)]
        [String]$Encoder,
        
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [String]$OBS64Path, # Indicate your OBS installation by passing -OBS64Path "C:\..\bin\64bit\obs64.exe"

        [String]$Preset = 'HighPerformance'
    )

    $OBSPatches = @{
        HighPerformance = @{
            NVENC = @{
                basic = @{
                    AdvOut = @{
                        RecEncoder = 'jim_nvenc'
                    }
                }
                recordEncoder = @{
                    rate_control = 'CQP'
                    cqp = 18
                    preset = 'hp'
                    psycho_aq = 'false'
                    keyint_sec = 0
                    profile = 'high'
                    lookahead = 'false'
                    bf = 0
                }
            }
            AMF = @{
                Basic = @{
                    ADVOut = @{
                        RecQuality='Small'
                        RecEncoder='amd_amf_h265'
                        FFOutputToFile='true'
                    }
                }
                recordEncoder = @{
                    'Interval.Keyframe'='0.0'
                    'QP.IFrame'=18
                    'QP.PFrame'=18
                    'lastVideo.API'="Direct3D 11"
                    'lastVideo.Adapter'=0
                    RateControlMethod=0
                    Version=6
                    lastRateControlMethod=0
                    lastVBVBuffer=0
                    lastView=0
                }
            }
            x264 = @{
                basic = @{
                    ADVOut = @{
                        RecEncoder='obs_x264'
                    }
                }
                recordEncoder = @{
                    crf=1
                    keyint_sec=1
                    preset='ultrafast'
                    profile='high'
                    rate_control='CRF'
                    x264opts='qpmin=15 qpmax=15 ref=0 merange=4 direct=none weightp=0 no-chroma-me'
                }
            }
        }
    }

    # Applies to all patches/presets
    $Global = @{
        basic = @{
            Output = @{
                RecType='Standard'
                Mode='Advanced'
            }
            AdvOut = @{
                RecRB='true'
            }
        }
    }
    $OBSPatches.$Preset.$Encoder = Merge-Hashtables $OBSPatches.$Preset.$Encoder $Global

    if (-Not($OBS64Path)){

        $Parameters = @{
            Path = @("$env:APPDATA\Microsoft\Windows\Start Menu","$env:ProgramData\Microsoft\Windows\Start Menu")
            Recurse = $True
            Include = 'OBS Studio*.lnk'
        }
        $StartMenu = Get-ChildItem @Parameters
        
        if (!$StartMenu){
            if ((Get-Process obs64 -ErrorAction Ignore).Path){$OBS64Path = (Get-Process obs64).Path} # Won't work if OBS is ran as Admin
            else{
return @'
Your OBS installation could not be found, 
please manually specify the path to your OBS64 executable, example:

Optimize-OBS -OBS64Path "D:\obs\bin\64bit\obs64.exe"

You can find it this way:             
 Searching up OBS -> 
 Open file location ->
 Open file location again if it's a shortcut ->
 Shift right click obs64.exe -> Copy as Path
'@
            }
        }
        if ($StartMenu.Count -gt 1){

            $Shortcuts = $null
            $StartMenu = Get-Item $StartMenu
            ForEach($Lnk in $StartMenu){$Shortcuts += @{$Lnk.BaseName = $Lnk.FullName}}
            "There are multiple OBS shortcuts in your Start Menu folder. Please select one."
            $ShortcutName = menu ($Shortcuts.Keys -Split [System.Environment]::NewLine)
            $StartMenu = $Shortcuts.$ShortcutName
            $OBS64Path = Get-ShortcutTarget $StartMenu
        }else{
            $OBS64Path = Get-ShortcutTarget $StartMenu
        }

    }

    Set-CompatibilitySettings $OBS64Path -RunAsAdmin

    if (Resolve-Path "$OBS64Path\..\..\..\portable_mode.txt" -ErrorAction Ignore){ # "Portable Mode" makes OBS make the config in it's own folder, else it's in appdata

        $ProfilesDir = (Resolve-Path "$OBS64Path\..\..\..\config\obs-studio\basic\profiles" -ErrorAction Stop)
    }else{
        $ProfilesDir = (Resolve-Path "$env:APPDATA\obs-studio\basic\profiles" -ErrorAction Stop)
    }
    $Profiles = Get-ChildItem $ProfilesDir

    ForEach($OBSProfile in $Profiles){$ProfilesHash += @{$OBSProfile.Name = $OBSProfile.FullName}}

    $ProfileNames = ($ProfilesHash.Keys -Split [System.Environment]::NewLine) + 'Create a new profile'
    "Please select a profile:"
    $OBSProfile = menu  $ProfileNames

    if ($OBSProfile -eq 'Create a new profile'){
        $NewProfileName = Read-Host "Enter a name for the new profile"
        $OBSProfile = Join-Path $ProfilesDir $NewProfileName
        New-Item -ItemType Directory -Path $OBSProfile -ErrorAction Stop
        $DefaultWidth, $DefaultHeight = ((Get-CimInstance Win32_VideoController).VideoModeDescription.Split(' x ') | Where-Object {$_ -ne ''} | Select-Object -First 2)
        if (!$DefaultWidth -or !$DefaultHeight){
            $DefaultWidth = 1920
            $DefaultHeight = 1080
        }
        Set-Content "$OBSProfile\basic.ini" -Value @"
[General]
Name=$NewProfileName

[Video]
BaseCX=$DefaultWidth
BaseCY=$DefaultHeight
OutputCX=$DefaultWidth
OutputCY=$DefaultHeight
"@
        Write-Host "Created new profile '$NewProfileName' with default resolution of $DefaultWidth`x$DefaultHeight" -For Green
    }else{
        $OBSProfile = $ProfilesHash.$OBSProfile
    }
    if ('basic.ini' -notin ((Get-ChildItem $OBSProfile).Name)){
       return "FATAL: Profile $OBSProfile is incomplete"
    }
    Write-Verbose "Tweaking profile $OBSProfile"

    $Basic = Get-IniContent "$OBSProfile\basic.ini" -ErrorAction Stop
    if ($Basic.Video.FPSCommon){ # Switch to fractional FPS
        $FPS=$Basic.Video.FPSCommon
        $Basic.Video.Remove('FPSCommon')
        $Basic.Video.FPSType = 2
        $Basic.Video.FPSNum = $FPS
        $Basic.Video.FPSDen = 1
    }elseif(!$Basic.Video.FPSCommon -and !$Basic.Video.FPSType){
        Write-Warning "Your FPS is at the default (30), you can go in Settings -> Video to set it to a higher value"
    }

    if ($Basic.RecRBSize -in 512,'',$null){
        $Basic.RecRBSize = 2048
    }

    if (!$Basic.Video.FPSDen){$Basic.Video.FPSDen = 1}

    $FPS = $Basic.Video.FPSNum/$Basic.Video.FPSDen
    $Pixels = [int]$Basic.Video.BaseCX*[int]$Basic.Video.BaseCY

    if (($Basic.AdvOut.RecTracks -NotIn '1','2') -And ($FPS -gt 120)){
        Write-Warning "Using multiple audio tracks while recording at a high FPS may cause OBS to fail to stop recording"
    }

    if (!$Basic.Hotkeys.ReplayBuffer){
        Write-Warning "Replay Buffer is enabled, but there's no hotkey to Save Replay, set it up in Settings -> Hotkeys"
    }

    $Basic = Merge-Hashtables -Original $Basic -Patch $OBSPatches.$Preset.$Encoder.basic -ErrorAction Stop
    Out-IniFile -FilePath "$OBSProfile\basic.ini" -InputObject $Basic -Pretty -Force

    $Base = "{0}x{1}" -f $Basic.Video.BaseCX,$Basic.Video.BaseCY
    $Output = "{0}x{1}" -f $Basic.Video.OutputCX,$Basic.Video.OutputCY
    if ($Base -Ne $Output){
        Write-Warning "Your Base/Canvas resolution ($Base) is not the same as the Output/Scaled resolution ($Output), this means OBS is scaling your video. This is not recommended."
    }

    $NoEncSettings = -Not(Test-Path "$OBSProfile\recordEncoder.json")
    $EmptyEncSettings = (Get-Content "$OBSProfile\recordEncoder.json" -ErrorAction Ignore) -in '',$null

    if ($NoEncSettings -or $EmptyEncSettings){
        Set-Content -Path "$OBSProfile\recordEncoder.json" -Value '{}' -Force 
    }
    $RecordEncoder = Get-Content "$OBSProfile\recordEncoder.json" | ConvertFrom-Json -ErrorAction Stop

    if (($Basic.Video.FPSNum/$Basic.Video.FPSDen -gt 480) -And ($Pixels -ge 2073600)){ # Set profile to baseline if recording at a high FPS and if res +> 2MP
        $RecordEncoder.Profile = 'baseline'
    }
    $RecordEncoder = Merge-Hashtables -Original $RecordEncoder -Patch $OBSPatches.$Preset.$Encoder.recordEncoder -ErrorAction Stop
    if ($Verbose){
        ConvertTo-Yaml $Basic
        ConvertTo-Yaml $RecordEncoder    
    }
    Set-Content -Path "$OBSProfile\recordEncoder.json" -Value (ConvertTo-Json -InputObject $RecordEncoder -Depth 100) -Force

}
function Optimize-OptiFine {
    [alias('optof')]
    param(
        [ValidateSet('Smart','Lowest')]
        [Parameter(Mandatory)]
        $Preset,
        [String]$CustomDirectory = (Join-path $env:APPDATA '.minecraft'),
        [Switch]$MultiMC,
        [Switch]$PolyMC,
        [Switch]$GDLauncher
    )

if($MultiMC){
    $CustomDirectory = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse | Where-Object Name -Like "MultiMC.lnk"
    $CustomDirectory = Get-ShortcutPath $CustomDirectory
    $Instances = Get-ChildItem (Join-Path (Split-Path $CustomDirectory) instances)
    "Please select a MultiMC instance"
    $CustomDirectory = menu (Get-ChildItem $Instances).Name
    $CustomDirectory = Join-Path $Instances $CustomDirectory

}elseif($PolyMC){
    $Instances = Get-ChildItem "$env:APPDATA\PolyMC\instances"
    "Please select a PolyMC instance"
    $CustomDirectory = menu $Instances.Name
    $CustomDirectory = Join-Path $Instances $CustomDirectory

}elseif($GDLauncher){
    $Instances = Get-ChildItem "$env:APPDATA\gdlauncher_next\instances"
    "Please select a GDLauncher instance"
    $CustomDirectory = menu $Instances.Name
    $CustomDirectory = Join-Path $Instances $CustomDirectory

}

$Presets = @{

    Smart = @{
        options = @{
            renderDistance=5
            mipmapLevels=4
            ofAoLevel=1.0
        }
        optionsof = @{
            ofMipmapType=3
            ofCustomSky=$true
        }
    }

    Lowest = @{
        options = @{
            gamma=1000000 # I've never tried anything else and this always worked
            renderDistance=2
            particles=2
            fboEnable=$true
            useVbo=$true
            showInventoryAchievementHint=$false
        }
        optionsof = @{
            ofAaLevel=0 # Anti-Aliasing
            ofDynamicLights=3
            ofChunkUpdates=1
            ofAoLevel=0.0 # Smooth lighting
            ofOcclusionFancy=$false
            ofSmoothWorld=$true
            ofClouds=3
            ofTrees=1
            ofDroppedItems=0
            ofRain=3
            ofAnimatedWater=2
            ofAnimatedLava=2
            ofAnimatedFire=$true
            ofAnimatedPortal=$false
            ofAnimatedRedstone=$false
            ofAnimatedExplosion=$false
            ofAnimatedFlame=$true
            ofAnimatedSmoke=$false
            ofVoidParticles=$false
            ofWaterParticles=$false
            ofPortalParticles=$false
            ofPotionParticles=$false
            ofFireworkParticles=$false
            ofDrippingWaterLava=$false
            ofAnimatedTerrain=$false
            ofAnimatedTextures=$false
            ofRainSplash=$false
            ofSky=$false
            ofStars=$false
            ofSunMoon=$false
            ofVignette=1
            ofCustomSky=$false
            ofShowCapes=$false
            ofFastMath=$true
            ofSmoothFps=$false
            ofTranslucentBlocks=1
        }
    }
}
$Global = @{
    optionsof = @{
        ofFastRender=$true
        ofClouds=3
        ofAfLevel=1 # Anisotropic filtering
        ofAaLevel=0 # Anti-aliasing
        ofRainSplash=$false
    }
    options = @{
        showInventoryAchievementHint=$false
        maxFps=260
        renderClouds=$false
        useVbo=$true
    }
}
$Presets.$Preset = Merge-Hashtables $Presets.$Preset $Global

function ConvertTo-MCSetting ($table){

    $file = @()
    ForEach($setting in $table.keys){
        $file += [String]$($setting + ':' + ($table.$setting)) -replace'True','true' -replace 'False','false'
    }
    return $file
}

foreach ($file in 'options','optionsof'){

    $Hash = (Get-Content "$CustomDirectory\$file.txt") -Replace ':','=' | ConvertFrom-StringData
    $Hash = Merge-Hashtables -Original $Hash -Patch $Presets.$Preset.$file
    Set-Content "$CustomDirectory\$file.txt" -Value (ConvertTo-MCSetting $Hash) -Force
}
$Hash = (Get-Content "$CustomDirectory\optionsLC.txt") -Replace ',"maxFps":"260"','' | ConvertFrom-Json
$Hash = Merge-Hashtables -Original $Hash -Patch $Presets.$Preset.optionsof
$Hash = Merge-Hashtables -Original $Hash -Patch $Presets.$Preset.options
$Hash.maxFPS = 260
Set-Content "$CustomDirectory\optionsLC.txt" -Value (ConvertTo-Json $Hash) -Force

}
function Install-MPVProtocol {
    param(
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $VideoPlayerFilePath
    )

if (!(Test-Admin)){
    "PowerShell NEEDS to run as Adminisrator in order to create the protocol handler"
    return
}


if ((Get-Command mpv -Ea 0) -and (Get-Command mpvnet -Ea 0)){
    "Would you like mpv:// links to open with MPV or MPV.net?"
    $Answer = Read-Host "Answer"
    while ($answer -notin 'mpv','mpv.net','mpvnet','exit'){
        "Answer must be mpv / mpvnet, type exit to quit"
    }
    switch ($Answer) {
        'exit'{return}
        {$_ -in 'mpvnet','mpv.net'}{$MPV = (Get-Command mpvnet.exe).Source}
        'mpv'{$MPV = (Get-Command mpv.exe).Source}
    }
}elseif(Get-Command mpv -Ea 0){
    "Using default MPV"
    $MPV = (Get-Command mpv.exe).Source
}elseif(Get-Command mpvnet -Ea 0){
    Write-Warning "Using MPV.net since MPV was not found (not added to path?)"
    $MPV = (Get-Command mpvnet.exe).Source
}else{
    return "MPV or MPV.net couldn't be found, please install MPV / MPV.net"
}

New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ea SilentlyContinue | Out-Null
New-Item -Path "HKCR:" -Name "mpv" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\mpv" -Name "(Default)" -Value '"URL:mpv Protocol"' | Out-Null
Set-ItemProperty -Path "HKCR:\mpv" -Name "URL Protocol" -Value '""' | Out-Null
New-Item -Path "HKCR:\mpv" -Name "shell" -Force | Out-Null
New-Item -Path "HKCR:\mpv\shell" -Name "open" -Force | Out-Null
New-Item -Path "HKCR:\mpv\shell\open" -Name "command" -Force | Out-Null
#Old command: "C:\ProgramData\CTT\mpv-protocol\mpv-protocol-wrapper.cmd" "%1"
$Command = "cmd /c title MPV && powershell -ep bypass -NoProfile `"& \`"$MPV\`" ('%1' -replace 'mpv://https//','https://')`""
Set-ItemProperty -Path "HKCR:\mpv\shell\open\command" -Name "(Default)" -Value  $Command | Out-Null

Write-Output "Added the registry keys to handle mpv protocol and redirect to wrapper!"

}
function Install-Voukoder {
    [alias('isvk')]
    param(
        [Switch]$GetTemplates = $false # Skip Voukoder installation
    )
    if ($PSEdition -eq 'Core'){return "Install-Voukoder is only available on Windows PowerShell 5.1 (use of Get-Package)."}
    if (!$GetTemplates){
        $LatestCore = (Invoke-RestMethod https://api.github.com/repos/Vouk/voukoder/releases)[0]
        if ($LatestCore.tag_name -notlike "*.*"){
            $LatestCore.tag_name = $LatestCore.tag_name + ".0"
        }
        [Version]$LatestCoreVersion = $LatestCore.tag_name
        $Core = Get-Package -Name "*Voukoder*" -ErrorAction Ignore | Where-Object Name -NotLike "*Connector*"
        if ($Core){
            $CurrentVersion = [Version]$Core.Version
            if ($LatestCoreVersion -gt $CurrentVersion){
                "Updating Voukoder Core from version $CurrentVersion to $LatestCoreVersion"
                Start-Process -FilePath msiexec -ArgumentList "/qb /x {$($Core.TagId)}" -Wait -NoNewWindow
            }
        }else{
            "Downloading and installing Voukoder Core.."
            $CoreURL = $LatestCore[0].assets[0].browser_download_url
            curl.exe -# -L $CoreURL -o"$env:TMP\Voukoder-Core.msi"
            msiexec /i "$env:TMP\Voukoder-Core.msi" /passive    
        }

        $Tree = (Invoke-RestMethod 'https://api.github.com/repos/Vouk/voukoder-connectors/git/trees/master?recursive=1').Tree
        
        ForEach($NLE in 'vegas','vegas18','aftereffects','premiere','resolve'){
            $Path = $Tree.path | Where-Object {$_ -Like "*$NLE-connector*"} | Sort-Object -Descending | Select-Object -First 1
            $Connectors += @{$NLE = "https://github.com/Vouk/voukoder-connectors/raw/master/$Path"}
        }
        $NLE = $null

        $Processes = @(
            'vegas*'
            'Adobe Premiere Pro'
            'AfterFX'
            'Resolve'
        )
        Write-Host "Looking for $($Processes -Join ', ').."

        While(!(Get-Process $Processes -ErrorAction Ignore)){
            Write-Host "`rScanning for any opened NLEs (video editors), press any key to refresh.." -NoNewline -ForeGroundColor Green
            Start-Sleep -Seconds 2
        }
        ''
        function Get-ConnectorVersion ($FileName){
            return $FileName.Trim('.msi').Trim('.zip').Split('-') | Select-Object -Last 1
        }
        function NeedsConnector ($PackageName, $Key){
            
            $CurrentConnector = (Get-Package -Name $PackageName -ErrorAction Ignore)
            if ($CurrentConnector){
                [Version]$CurrentConnectorVersion = $CurrentVersion.Version
                [Version]$LatestConnector = Get-ConnectorVersion $Connectors.$key
                if ($LatestConnector -gt $CurrentConnectorVersion){
                    msiexec /uninstall $CurrentConnectorVersion.TagId /qn
                    return $True
                }
            }
            return $False
        }
        $NLEs = Get-Process $Processes -ErrorAction Ignore
        ForEach($NLE in $NLEs){
            switch (Split-Path $NLE.Path -Leaf){
                {$_ -in 'vegas180.exe', 'vegas190.exe'} {
                    Write-Verbose "Found VEGAS18+"

                    if (NeedsConnector -PackageName 'Voukoder connector for VEGAS' -Key 'vegas18'){
                        continue
                    }
                    $Directory = Split-Path $NLE.Path -Parent
                    curl.exe -# -L $Connectors.vegas18 -o"$env:TMP\Voukoder-Connector-VEGAS18.msi"
                    msiexec /i "$env:TEMP\Voukoder-Connector-VEGAS18.msi" /qb "VEGASDIR=`"$Directory`""
                    continue
                }
                {$_ -Like 'vegas*.exe'}{
                    Write-Verbose "Found old VEGAS"
                    if (NeedsConnector -PackageName 'Voukoder connector for VEGAS' -Key 'vegas'){
                        continue
                    }
                    $Directory = Split-Path $NLE.Path -Parent
                    curl.exe -# -L $Connectors.vegas18 -o"$env:TMP\Voukoder-Connector-VEGAS.msi"
                    msiexec /i "$env:TEMP\Voukoder-Connector-VEGAS.msi" /qb "VEGASDIR=`"$Directory`""
                    continue
                }
                'afterfx.exe' {
                    if (NeedsConnector -PackageName 'Voukoder connector for After Effects' -Key 'aftereffects'){
                        continue
                    }
                    $Directory = Split-Path $NLE.Path -Parent
                    curl.exe -# -L $Connectors.aftereffects -o"$env:TMP\AE.msi"
                    msiexec /i "$env:TEMP\Voukoder-Connector-AE.msi" /qb "INSTALLDIR=`"$env:ProgramFiles\Adobe\Common\Plug-ins\7.0\MediaCore`""
                }
                'Adobe Premiere Pro.exe'{
                    if (NeedsConnector -PackageName 'Voukoder connector for Premiere Pro' -Key 'premiere'){
                        continue
                    }
                    $Directory = Split-Path $NLE.Path -Parent
                    curl.exe -# -L $Connectors.premiere -o"$env:TMP\Voukoder-Connector-Premiere.msi"
                    msiexec /i "$env:TMP\Voukoder-Connector-Premiere.msi" /qb "TGTDir=`"$env:ProgramFiles\Adobe\Common\Plug-ins\7.0\MediaCore`""
                }
                'Resolve'{
                    $IOPlugins = "$env:ProgramData\Blackmagic Design\DaVinci Resolve\Support\IOPlugins"
                    New-Item -ItemType Directory -Path $IOPlugins -ErrorAction Ignore | Out-Null
                    if (Test-Path "$IOPlugins\voukoder_plugin.dvcp.bundle"){
                        if (-Not(Get-Boolean "Would you like to reinstall/update the Voukoder Resolve plugin? (Y/N)")){continue}
                        Remove-Item "$IOPlugins\voukoder_plugin.dvcp.bundle" -Force -Recurse
                    }
                    curl.exe -# -L $Connectors.Resolve -o"$env:TMP\Voukoder-Connector-Resolve.zip"
                    Remove-Item "$env:TMP\Voukoder-Connector-Resolve" -Recurse -Force -ErrorAction Ignore
                    $ExtractDir = "$env:TMP\Voukoder-Connector-Resolve"
                    Expand-Archive "$env:TMP\Voukoder-Connector-Resolve.zip" -Destination $ExtractDir
                    Copy-Item "$ExtractDir\resolve-connector-*\voukoder_plugin.dvcp.bundle" $IOPlugins
                }
            }
        }
    }

    $TemplatesFolder = "$env:APPDATA\VEGAS\Render Templates\voukoder"
    New-Item -ItemType Directory -Path "$env:APPDATA\VEGAS\Render Templates\voukoder" -Force -ErrorAction Ignore | Out-Null

    $Templates = [Ordered]@{
        'HEVC NVENC + Upscale' = 'https://cdn.discordapp.com/attachments/969870701798522901/972541638578667540/HEVC_NVENC_Upscale.sft2'
        'HEVC NVENC' =           'https://cdn.discordapp.com/attachments/969870701798522901/972541638733885470/HEVC_NVENC.sft2'
        'H264 NVENC + Upscale' = 'https://cdn.discordapp.com/attachments/969870701798522901/972541639744688198/H264_NVENC_Upscale.sft2'
        'H264 NVENC' =           'https://cdn.discordapp.com/attachments/969870701798522901/972541638356389918/H264_NVENC.sft2'
        'x265 + Upscale' =       'https://cdn.discordapp.com/attachments/969870701798522901/972541639346225264/x265_Upscale.sft2'
        'x265' =                 'https://cdn.discordapp.com/attachments/969870701798522901/972541639560163348/x265.sft2'
        'x264 + Upscale' =       'https://cdn.discordapp.com/attachments/969870701798522901/972541638943596574/x264_Upscale.sft2'
        'x264' =                 'https://cdn.discordapp.com/attachments/969870701798522901/972541639128129576/x264.sft2'
    }

    $SelectedTemplates = Write-Menu -Entries @($Templates.Keys) -MultiSelect -Title @"
Tick/untick the render templates you'd like to install by pressing SPACE, then press ENTER to finish.
NVENC (for NVIDIA GPUs) is much faster than libx265, but will give you a bigger file to upload.
"@
    ForEach ($Template in $SelectedTemplates){
        Remove-Item "$TemplatesFolder\$Template.sft2" -Force -ErrorAction Ignore
        curl.exe -# -sSL $Templates.$Template -o"$TemplatesFolder\$Template.sft2"
    }
    Write-Output "Installation script finished, restart your NLE to see the new render templates."
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

function Add-ToContextMenu {
    param(
        [ValidateSet(
            'SendTo',
            'TakeOwnership',
            'OpenWithOnBatchFiles'
            )]
        [Array]$Entries
    )

    if ('SendTo' -in $Entries){
        New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo -Name "(default)" -PropertyType String -Value "{7BA4C740-9E81-11CF-99D3-00AA004AE837}" -Force
    }

    if ('OpenWithOnBatchFiles' -in $Entries){
        New-Item -Path "Registry::HKEY_CLASSES_ROOT\batfile\shell\Open with\command" -Force
        Set-ItemProperty "Registry::HKEY_CLASSES_ROOT\batfile\shell\Open with\command" -Name "(Default)" -Value "{09799AFB-AD67-11d1-ABCD-00C04FC30936}" -Force

    }

    if ('TakeOwnerShip' -in $Entries){
        '*','Directory' | ForEach-Object {
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\$_\shell\runas"
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name '(Default)' -Value 'Take Ownership'
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name 'NoWorkingDirectory' -Value ''
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name 'HasLUAShield' -Value ''
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name 'Position' -Value 'Middle'
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name 'AppliesTo' -Value "NOT (System.ItemPathDisplay:=`"$env:HOMEDRIVE\`")"

            New-Item -Path "Registry::HKEY_CLASSES_ROOT\$_\shell\runas\command"
            $Command = 'cmd.exe /c title Taking ownership.. & mode con:lines=30 cols=150 & takeown /f "%1" && icacls "%1" /grant administrators:F & timeout 2 >nul'
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas\command" -Name '(Default)' -Value $Command
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas\command" -Name 'IsolatedCommand' -Value $Command

        }
    }

}
function Block-RazerSynapse {
    Try {
        Remove-Item "C:\Windows\Installer\Razer" -Force -Recurse
    } Catch {
        "Failed to remove Razer installer folder"
        $_.Exception.Message
    }
    New-Item -ItemType File -Path "C:\Windows\Installer\Razer" -Force -ErrorAction Stop
    Write-Host "An empty file called 'Razer' in C:\Windows\Installer has been put to block Razer Synapse's auto installation"
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
        return "GraalVM is already installed, run with -Reinstall to force reinstallation"
    }
    if (-Not(Get-Command curl.exe -ErrorAction Ignore)){
        return "curl is not found (comes with windows per default?)"
    }
    Remove-Item "$env:ProgramData\GraalVM" -ErrorAction Ignore -Force -Recurse

    $URL = 'https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-21.2.0/graalvm-ce-java16-windows-amd64-21.2.0.zip'
    $SHA256 = 'DAE2511ABFF8EAD3EBC90CD9FC81A8E84B762FC91462B198C3EDDF28F81A937E'
    $Zip = "$env:TMP\GraalVM.zip"


    if (-Not(Test-Path $Zip)){
        Write-Host "Downloading GraalVM ($(Get-HeaderSize $URL)`MB).." -ForegroundColor Green
        curl.exe -# -L $URL -o"$Zip"
    }

    if ((Get-FileHash $Zip).Hash -ne $SHA256){
        Remove-Item "$env:TMP\GraalVM.zip"
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
        [Parameter(ValueFromRemainingArguments = $true)]
        [Array]$Apps
    )

    $FailedToInstall = $null # Reset that variable for later

    ForEach($App in $Apps){ # Scoop exits when it throws

        switch ($App){
            'Voukoder'{Install-Voukoder}
            'Upscaler'{

                Install-FFmpeg
                Invoke-RestMethod 'https://github.com/couleur-tweak-tips/utils/raw/main/Miscellaneous/CTT%20Upscaler.cmd' |
                Out-File (Join-Path ([System.Environment]::GetFolderPath('SendTo')) 'CTT Upscaler.cmd') -Encoding ASCII -Force
                Write-Host @"
CTT Upscaler has been installed,
I strongly recommend you open settings to tune it to your PC, there's lots of cool stuff to do there!
"@ -ForegroundColor Green

            }
            {$_ -In 'QualityMuncher','qm'}{
                Install-FFmpeg

                Invoke-RestMethod 'https://raw.githubusercontent.com/Thqrn/qualitymuncher/main/Quality%20Muncher.bat' |
                Out-File (Join-Path ([System.Environment]::GetFolderPath('SendTo')) 'Quality Muncher.bat') -Encoding ASCII -Force

                Invoke-RestMethod 'https://raw.githubusercontent.com/Thqrn/qualitymuncher/main/!!qualitymuncher%20multiqueue.bat' |
                Out-File (Join-Path ([System.Environment]::GetFolderPath('SendTo')) '!!qualitymuncher multiqueue.bat') -Encoding ASCII -Force

            }

            'Scoop'{Install-Scoop}
            'FFmpeg'{Install-FFmpeg}
            {$_ -in 'CRU','custom-resolution-utility'}{Get-ScoopApp extras/cru}
            {$_ -in 'Notepad++','notepadplusplus'}{Get-ScoopApp extras/notepadplusplus}
            {$_ -in 'DDU','DisplayDriverUninstaller'}{Get-ScoopApp extras/ddu}
            {$_ -in 'Afterburner','MSIAfterburner'}{Get-ScoopApp utils/msiafterburner}
            {$_ -in 'Everything','Everything-Alpha','Everything-Beta'}{Get-ScoopApp extras/everything-alpha}
            {$_ -In '7-Zip','7z','7Zip'}{Get-ScoopApp 7zip}
            {$_ -In 'Smoothie','sm'}{Install-FFmpeg;Get-ScoopApp utils/Smoothie}
            {$_ -In 'OBS','OBStudio'}{Get-ScoopApp extras/obs-studio}
            {$_ -In 'UTVideo'}{Get-ScoopApp utils/utvideo}
            {$_ -In 'Nmkoder'}{Get-ScoopApp utils/nmkoder}
            {$_ -In 'Librewolf'}{Get-ScoopApp extras/librewolf}
            {$_ -In 'ffmpeg-nightly'}{Get-ScoopApp versions/ffmpeg-nightly}
            {$_ -In 'Graal','GraalVM'}{Get-ScoopApp utils/GraalVM}
            {$_ -In 'DiscordCompressor','dc'}{Install-FFmpeg;Get-ScoopApp utils/discordcompressor}
            {$_ -In 'Moony','mn'}{if (-Not(Test-Path "$HOME\.lunarclient")){Write-Warning "You NEED Lunar Client to launch it with Moony"};Get-ScoopApp utils/Moony}
            {$_ -In 'TLShell','TLS'}{Get-TLShell}
            default{Get-ScoopApp $App}
        }
        Write-Verbose "Finished installing $app"

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
    param(
        [Switch]$Write
    )

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

    if ($Write){
        return $SophiaFunctions
    }else{
        Invoke-Expression $SophiaFunctions
    }

}
function Invoke-GitHubScript {
    [alias('igs')]
    param(
        [ValidateSet(
            'ChrisTitusTechToolbox',
            'OldChrisTitusTechToolbox',
            'Fido',
            'SophiaScript'
        )]
        $Repository,
        $RawURL
    )
    if ($RawURL){
        Invoke-RestMethod $URL | Invoke-Expression
        return
    }
    function Invoke-URL ($Link) {
        $Response = Invoke-RestMethod $Link
        While ($Response[0] -NotIn '<','#'){ # Byte Order Mark (BOM) removal
            $Response = $Response.Substring(1)
        }
        Invoke-Expression $Response
    }
    switch ($Repository){
        'ChrisTitusTechToolbox'{Invoke-URL https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1}
        'OldChrisTitusTechToolbox'{Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/win10debloat.ps1)}
        'Fido'{Invoke-URL https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1}
        'SophiaScript'{Import-Sophia}
    }
}
function Remove-ContextMenu {
    [alias('rcm')]
    <#
    https://www.tenforums.com
    https://winaero.com
    https://majorgeeks.com
    https://github.com/farag2/Sophia-Script-for-Windows
    #>
    param(
        [ValidateSet(
            'PinToQuickAccess',
            'RestorePreviousVersions',
            'Print',
            'GiveAccessTo',
            'EditWithPaint3D',
            'IncludeInLibrary',
            'AddToWindowsMediaPlayerList',
            'CastToDevice',
            'EditWithPaint3D',
            'EditWithPhotos',
            'Share',
            'TakeOwnerShip',
            '7Zip',
            'WinRAR',
            'Notepad++',
            'OpenWithOnBatchFiles',
            'SendTo'
            )]
        [Array]$Entries
    )

    $CurrentPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Ignore'
    $Blocked = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"

    if (-Not (Test-Path -Path $Blocked)){
        New-Item -Path $Blocked -Force
    }

    if ('RestorePreviousVersions' -in $Entries){
        New-ItemProperty -Path "$Blocked" -Name "{596AB062-B4D2-4215-9F74-E9109B0A8153}"
    }

    if ('PinToQuickAccess'){
        @('HKEY_CLASSES_ROOT','HKEY_LOCAL_MACHINE\SOFTWARE\Classes') |
        ForEach-Object { Remove-Item "Registry::$_\Folder\shell\pintohome" -Force -Recurse}
    }

    if ('Print' -in $Entries){
        @(
            'SystemFileAssociations\image',
            'batfile','cmdfile','docxfil','fonfile','htmlfil','inffile','inifile','VBSFile','WSFFile',
            'JSEFile','otffile','pfmfile','regfile','rtffile','ttcfile','ttffile','txtfile','VBEFile'
        ) | ForEach-Object {Set-ItemProperty "Registry::HKEY_CLASSES_ROOT\$_\shell\print" -Name "ProgrammaticAccessOnly" -Value ''}
    }

    if ('GiveAccessTo' -in $Entries) {
        @('*','Directory\Background','Directory','Drive','LibraryFolder\background','UserLibraryFolder') |
        ForEach-Object {Remove-Item -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shellex\ContextMenuHandlers\Sharing" -Recurse -Force}
    }

    if ('IncludeInLibrary' -in $Entries){
        @('HKEY_LOCAL_MACHINE\SOFTWARE\Classes','HKEY_CLASSES_ROOT') |
        ForEach-Object {Remove-Item "Registry::$_\Folder\ShellEx\ContextMenuHandlers\Library Location" -Force}
    }

    if ('AddToWindowsMediaPlayerList' -in $Entries){
        @(
            '3G2','3GP','ADTS','AIFF','ASF','ASX','AU','AVI','FLAC','M2TS','m3u','M4A','MIDI','MK3D',
            'MKA','MKV','MOV','MP3','MP4','MPEG','TTS','WAV','WAX','WMA','WMV','WPL','WVX'
        ) | ForEach-Object { Remove-Item "Registry::HKEY_CLASSES_ROOT\WMP11.AssocFile.$_\shell\Enqueue" -Force -Recurse }

        @(
            'MediaCenter.WTVFile','Stack.Audio','Stack.Image','SystemFileAssociations\audio','WMP.WTVFile',
            'SystemFileAssociations\Directory.Audio','SystemFileAssociations\Directory.Image','WMP.DVR-MSFile','WMP.DVRMSFile'
        ) | ForEach-Object { Remove-Item "Registry::HKEY_CLASSES_ROOT\$_\shell\Enqueue" -Force -Recurse}
    }

    if ('CastToDevice' -in $Entries){
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" -Name "{7AD84985-87B4-4a16-BE58-8B72A5B390F7}" -PropertyType String -Value "Play to menu" -Force
    }

    if ('EditWithPaint3D' -in $Entries){
        @('.3mf','.bmp','.fbx','.gif','.jfif','.jpe','.jpeg','.jpg','.png','.tif','.tiff') | 
        ForEach-Object { Remove-Item "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\$_\Shell\3D Edit" -Force -Recurse}
    }

    if ('EditWithPhotos' -in $Entries){
        Set-ItemProperty "Registry::HKEY_CLASSES_ROOT\AppX43hnxtbyyps62jhe9sqpdzxn1790zetc\Shell\ShellEdit" -Name 'ProgrammaticAccessOnly' -Value ''
    }

    if ('Share' -in $Entries){
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" -Name "{E2BF9676-5F8F-435C-97EB-11607A5BEDF7}" -PropertyType String -Value "" -Force
    }

    if ('TakeOwnerShip' -in $Entries){
        @(
        'HKEY_CLASSES_ROOT\*\shell\runas'
        'HKEY_CLASSES_ROOT\Directory\shell\runas'
        'HKEY_CLASSES_ROOT\*\shell\TakeOwnership'
        'HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership'
        'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\*\shell\TakeOwnership'
        'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\*\shell\TakeOwnership'
        'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Directory\shell\TakeOwnership'
        ) | ForEach-Object {
            Remove-Item -LiteralPath "Registry::$_" -Recurse -Force
        }
    }

    if ('SendTo' -in $Entries){
        $DefaultSendTo = (
        'Bluetooth File Transfer',
        'Compressed (zipped) Folder',
        'Desktop (create shortcut)',
        'Documents',
        'Fax Recipient',
        'Mail Recipient'
        )
        $NonDefaultSendTo = Get-ChildItem ([System.Environment]::GetFolderPath('SendTo')) | Where-Object BaseName -NotIn $DefaultSendTo
        if ($NonDefaultSendTo) {
            $NonDefaultSendTo.Name
            if(Get-Boolean "Are you sure you wish to lose access the following files/scripts?"){
                New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo -Name "(default)" -PropertyType String -Value "-{7BA4C740-9E81-11CF-99D3-00AA004AE837}" -Force
            }
        }else{
            New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo -Name "(default)" -PropertyType String -Value "-{7BA4C740-9E81-11CF-99D3-00AA004AE837}" -Force
        }
    }
    
    if ('OpenWithOnBatchFiles' -in $Entries){
        Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\batfile\shell\Open with\command" -Force -Recurse
    }

    if ('7Zip' -in $Entries){
        @(
            'Classes\CLSID\{23170F69-40C1-278A-1000-000100020000}',
            'Classes\CLSID\{23170F69-40C1-278A-1000-000100020000}\InprocServer32',
            'Classes\*\shellex\ContextMenuHandlers\7-Zip',
            'Classes\Directory\shellex\ContextMenuHandlers\7-Zip',
            'Classes\Folder\shellex\ContextMenuHandlers\7-Zip',
            '7-Zip\Options'
        ) | ForEach-Object {Remove-Item -LiteralPath "REGISTRY::HKEY_CURRENT_USER\Software\$_" -Recurse -Force}
    }
    if ('WinRAR' -in $Entries){ # This hides (adds to Blocked) instead of deleting
        @('{B41DB860-64E4-11D2-9906-E49FADC173CA}','{B41DB860-8EE4-11D2-9906-E49FADC173CA}') |
        ForEach-Object {New-ItemProperty -Path $Blocked -Name $_ -Value ''}
    }

    if ('Notepad++' -in $Entries){
        @(
            '*\shell\Open with &Notepad++',
            '*\shell\Open with &Notepad++\command',
            'Directory\shell\Open with &Notepad++',
            'Directory\shell\Open with &Notepad++\command',
            'Directory\Background\shell\Open with &Notepad++',
            'Directory\Background\shell\Open with &Notepad++\command'
        ) | ForEach-Object {
            Remove-Item -LiteralPath "Registry::HKEY_CURRENT_USER\Software\Classes\$_" -Recurse -Force
        }

    }

    $ErrorActionPreference = $CurrentPreference
}
function Remove-FromThisPC {
    param(
        [ValidateSet('Remove','Restore')]
        [String]
        $Action = 'Remove',

        [ValidateSet(
            'Desktop',
            'Documents',
            'Downloads',
            'Music',
            'Pictures',
            'Videos'
            )]
        $Entries,
        [Switch]$All

    )
    if ($All){$Entries = 'Desktop','Documents','Downloads','Music','Pictures','Videos'}
    function Modify-Entry ($GUID){
        if ($Action -eq 'Remove'){
            Remove-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}"
            Remove-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}"    
        }else{
            New-Item -ItemType -Directory -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}" | Out-Null
            New-Item -ItemType -Directory -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}" | Out-Null
        }
        
    }
    ForEach($Entry in $Entries){
        Switch($Entry){
            'Desktop'{
                Modify-Entry B4BFCC3A-DB2C-424C-B029-7FE99A87C641
            }
            'Documents'{
                Modify-Entry A8CDFF1C-4878-43be-B5FD-F8091C1C60D0
                Modify-Entry d3162b92-9365-467a-956b-92703aca08af
            }
            'Downloads'{
                Modify-Entry 374DE290-123F-4565-9164-39C4925E467B
                Modify-Entry 088e3905-0323-4b02-9826-5d99428e115f
            }
            'Music'{
                Modify-Entry 1CF1260C-4DD0-4ebb-811F-33C572699FDE
                Modify-Entry 3dfdf296-dbec-4fb4-81d1-6a3438bcf4de
            }
            'Pictures'{
                Modify-Entry 3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA
                Modify-Entry 24ad3ad4-a569-4530-98e1-ab02f9417aa8
            }
            'Videos'{
                Modify-Entry A0953C92-50DC-43bf-BE83-3742FED03C9C
                Modify-Entry f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a
            }

        }
    }
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

    New-Item -ItemType Directory -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -ErrorAction Ignore
    New-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" `
    -Name $FilePath.FullName -PropertyType String -Value $Data -Force | Out-Null

}
# Default is 400(ms)
function Set-MenuShowDelay {
    param(
        [Int]$DelayInMs
    )
    
    Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" -Name MenuShowDelay -PropertyType String -Value $DelayInMs -Force
}
