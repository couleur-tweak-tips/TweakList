# This file is automatically built at every commit to add up every function to a single file, this makes it simplier to parse (aka download) and execute.

using namespace System.Management.Automation # Needed by Invoke-NGENposh
$CommitCount = 226
$FuncsCount = 60
function Get-IniContent {
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
    if ((Get-Command $FunctionName).ResolvedCommand){
        Write-Verbose "Switching from alias $FunctionName to function $(((Get-Command $FunctionName).ResolvedCommand).Name)"
        $FunctionName = ((Get-Command $FunctionName).ResolvedCommand).Name
    }
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

        main = @{org = 'ScoopInstaller';repo = 'main';branch = 'master'}
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
function HEVCCheck {

    if ((cmd /c .mp4) -eq '.mp4=WMP11.AssocFile.MP4'){ # If default video player for .mp4 is Movies & TV
        
        if(Test-Path "Registry::HKEY_CLASSES_ROOT\ms-windows-store"){
            "Opening HEVC extension in Windows Store.."
            Start-Process ms-windows-store://pdp/?ProductId=9n4wgh0z6vhq
        }
    }
}
function Install-FFmpeg {

    $IsFFmpegScoop = (Get-Command ffmpeg -Ea Ignore).Source -Like "*\shims\*"

    if(Get-Command ffmpeg -Ea Ignore){

        $IsFFmpeg5 = (ffmpeg -hide_banner -h filter=libplacebo) -ne "Unknown filter 'libplacebo'."

        if (-Not($IsFFmpeg5)){

            if ($IsFFmpegScoop){
                Get Scoop
                scoop update ffmpeg
            }else{
                Write-Warning @"
An old FFmpeg installation was detected @ ($((Get-Command FFmpeg).Source)),

You could encounter errors such as:
- Encoding with NVENC failing (in simple terms not being able to render with your GPU)
- Scripts using new filters (e.g libplacebo)

If you want to update FFmpeg yourself, you can remove it and use the following command to install ffmpeg and add it to the path:
iex(irm tl.ctt.cx);Get FFmpeg

If you're using it because you prefer old NVIDIA drivers (why) here be dragons!
"@
pause
                
            }
            
        }
                
    }else{
        Get Scoop
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
<#
	.LINK
	Frankensteined from Inestic's WindowsFeatures Sophia Script function
	https://github.com/Inestic
	https://github.com/farag2/Sophia-Script-for-Windows/blob/06a315c643d5939eae75bf6e24c3f5c6baaf929e/src/Sophia_Script_for_Windows_10/Module/Sophia.psm1#L4946

	.SYNOPSIS
	User gets a nice checkbox-styled menu in where they can select 
	
	.EXAMPLE

	Screenshot: https://i.imgur.com/zrCtR3Y.png

	$ToInstall = Invoke-CheckBox -Items "7-Zip", "PowerShell", "Discord"

	Or you can have each item have a description by passing an array of hashtables:

	$ToInstall = Invoke-CheckBox -Items @(

		@{
			DisplayName = "7-Zip"
			# Description = "Cool Unarchiver"
		},
		@{
			DisplayName = "Windows Sandbox"
			Description = "Windows' Virtual machine"
		},
		@{
			DisplayName = "Firefox"
			Description = "A great browser"
		},
		@{
			DisplayName = "PowerShell 777"
			Description = "PowerShell on every system!"
		}
	)
#>
function Invoke-Checkbox{
param(
	$Title = "Select an option",
	$ButtonName = "Confirm",
	$Items = @("Fill this", "With passing an array", "to the -Item param!")
)

if (!$Items.Description){
	$NewItems = @()
	ForEach($Item in $Items){
		$NewItems += @{DisplayName = $Item}
	}
	$Items = $NewItems
} 

Add-Type -AssemblyName PresentationCore, PresentationFramework

# Initialize an array list to store the selected Windows features
$SelectedFeatures = New-Object -TypeName System.Collections.ArrayList($null)
$ToReturn = New-Object -TypeName System.Collections.ArrayList($null)


#region XAML Markup
# The section defines the design of the upcoming dialog box
[xml]$XAML = '
<Window
	xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
	xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
	Name="Window"
	MinHeight="450" MinWidth="400"
	SizeToContent="WidthAndHeight" WindowStartupLocation="CenterScreen"
	TextOptions.TextFormattingMode="Display" SnapsToDevicePixels="True"
	FontFamily="Arial" FontSize="16" ShowInTaskbar="True"
	Background="#F1F1F1" Foreground="#262626">

	<Window.TaskbarItemInfo>
		<TaskbarItemInfo/>
	</Window.TaskbarItemInfo>
	
	<Window.Resources>
		<Style TargetType="StackPanel">
			<Setter Property="Orientation" Value="Horizontal"/>
			<Setter Property="VerticalAlignment" Value="Top"/>
		</Style>
		<Style TargetType="CheckBox">
			<Setter Property="Margin" Value="10, 10, 5, 10"/>
			<Setter Property="IsChecked" Value="True"/>
		</Style>
		<Style TargetType="TextBlock">
			<Setter Property="Margin" Value="5, 10, 10, 10"/>
		</Style>
		<Style TargetType="Button">
			<Setter Property="Margin" Value="25"/>
			<Setter Property="Padding" Value="15"/>
		</Style>
		<Style TargetType="Border">
			<Setter Property="Grid.Row" Value="1"/>
			<Setter Property="CornerRadius" Value="0"/>
			<Setter Property="BorderThickness" Value="0, 1, 0, 1"/>
			<Setter Property="BorderBrush" Value="#000000"/>
		</Style>
		<Style TargetType="ScrollViewer">
			<Setter Property="HorizontalScrollBarVisibility" Value="Disabled"/>
			<Setter Property="BorderBrush" Value="#000000"/>
			<Setter Property="BorderThickness" Value="0, 1, 0, 1"/>
		</Style>
	</Window.Resources>
	<Grid>
		<Grid.RowDefinitions>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="*"/>
			<RowDefinition Height="Auto"/>
		</Grid.RowDefinitions>
		<ScrollViewer Name="Scroll" Grid.Row="0"
			HorizontalScrollBarVisibility="Disabled"
			VerticalScrollBarVisibility="Auto">
			<StackPanel Name="PanelContainer" Orientation="Vertical"/>
		</ScrollViewer>
		<Button Name="Button" Grid.Row="2"/>
	</Grid>
</Window>
'
#endregion XAML Markup

$Form = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$XAML.SelectNodes("//*[@Name]") | ForEach-Object {
	Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)
}

#region Functions
function Get-CheckboxClicked
{
	[CmdletBinding()]
	param
	(
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $true
		)]
		[ValidateNotNull()]
		$CheckBox
	)

	$Feature = $Items | Where-Object -FilterScript {$_.DisplayName -eq $CheckBox.Parent.Children[1].Text}

	if ($CheckBox.IsChecked)
	{
		[void]$SelectedFeatures.Add($Feature)
	}
	else
	{
		[void]$SelectedFeatures.Remove($Feature)
	}
	if ($SelectedFeatures.Count -gt 0)
	{
		$Button.Content = $ButtonName
		$Button.IsEnabled = $true
	}
	else
	{
		$Button.Content = "Cancel"
		$Button.IsEnabled = $true
	}
}

function DisableButton
{
	[void]$Window.Close()

	#$SelectedFeatures | ForEach-Object -Process {Write-Verbose $_.DisplayName -Verbose}
	$SelectedFeatures.DisplayName
	$ToReturn.Add($SelectedFeatures.DisplayName)
}

function Add-FeatureControl
{
	[CmdletBinding()]
	param
	(
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $true
		)]
		[ValidateNotNull()]
		$Feature
	)

	process
	{
		$CheckBox = New-Object -TypeName System.Windows.Controls.CheckBox
		$CheckBox.Add_Click({Get-CheckboxClicked -CheckBox $_.Source})
		if ($Feature.Description){
			$CheckBox.ToolTip = $Feature.Description
		}

		$TextBlock = New-Object -TypeName System.Windows.Controls.TextBlock
		#$TextBlock.On_Click({Get-CheckboxClicked -CheckBox $_.Source})
		$TextBlock.Text = $Feature.DisplayName
		if ($Feature.Description){
			$TextBlock.ToolTip = $Feature.Description
		}

		$StackPanel = New-Object -TypeName System.Windows.Controls.StackPanel
		[void]$StackPanel.Children.Add($CheckBox)
		[void]$StackPanel.Children.Add($TextBlock)
		[void]$PanelContainer.Children.Add($StackPanel)

		$CheckBox.IsChecked = $false

		# If feature checked add to the array list
		[void]$SelectedFeatures.Add($Feature)
		$SelectedFeatures.Remove($Feature)
	}
}
#endregion Functions

# Getting list of all optional features according to the conditions


# Add-Type -AssemblyName System.Windows.Forms



# if (-not ("WinAPI.ForegroundWindow" -as [type]))
# {
# 	Add-Type @SetForegroundWindow
# }

# Get-Process | Where-Object -FilterScript {$_.Id -eq $PID} | ForEach-Object -Process {
# 	# Show window, if minimized
# 	[WinAPI.ForegroundWindow]::ShowWindowAsync($_.MainWindowHandle, 10)

# 	#Start-Sleep -Seconds 1

# 	# Force move the console window to the foreground
# 	[WinAPI.ForegroundWindow]::SetForegroundWindow($_.MainWindowHandle)

# 	#Start-Sleep -Seconds 1

# 	# Emulate the Backspace key sending
# 	[System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE 1}")
# }
# #endregion Sendkey function

$Window.Add_Loaded({$Items | Add-FeatureControl})
$Button.Content = $ButtonName
$Button.Add_Click({& DisableButton})
$Window.Title = $Title

# ty chrissy <3 https://blog.netnerds.net/2016/01/adding-toolbar-icons-to-your-powershell-wpf-guis/
$base64 = "iVBORw0KGgoAAAANSUhEUgAAACoAAAAqCAMAAADyHTlpAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAPUExURQAAAP///+vr6+fn5wAAAD8IT84AAAAFdFJOU/////8A+7YOUwAAAAlwSFlzAAALEwAACxMBAJqcGAAAANBJREFUSEut08ESgjAMRVFQ/v+bDbxLm9Q0lRnvQtrkDBt1O4a2FoNWHIBajJW/sQ+xOnNnlkMsrXZkkwRolHHaTXiUYfS5SOgXKfuQci0T5bLoIeWYt/O0FnTfu62pyW5X7/S26D/yFca19AvBXMaVbrnc3n6p80QGq9NUOqtnIRshhi7/ffHeK0a94TfQLQPX+HO5LVef0cxy8SX/gokU/bIcQvxjB5t1qYd0aYWuz4XF6FHam/AsLKDTGWZpuWNqWZ358zdmrOLNAlkM6Dg+78AGkhvs7wgAAAAASUVORK5CYII="
 
 
# Create a streaming image by streaming the base64 string to a bitmap streamsource
$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64)
$bitmap.EndInit()
$bitmap.Freeze()

# This is the icon in the upper left hand corner of the app
# $Form.Icon = $bitmap
 
# This is the toolbar icon and description
$Form.TaskbarItemInfo.Overlay = $bitmap
$Form.TaskbarItemInfo.Description = $window.Title

# # Force move the WPF form to the foreground
# $Window.Add_Loaded({$Window.Activate()})
# $Form.ShowDialog() | Out-Null
# return $ToReturn

# [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($Form)

Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration
$window.Add_Closing({[System.Windows.Forms.Application]::Exit()})

$Form.Show()

# This makes it pop up
$Form.Activate() | Out-Null
 
# Create an application context for it to all run within. 
# This helps with responsiveness and threading.
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext) 
return $ToReturn
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


function IsCustomISO {
    switch (
        Get-ItemProperty "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
    ){
        {$_.SupportURL -Like "https://atlasos.net*"}{return 'AtlasOS'}
        {$_.Manufacturer -eq "Revision"}{return 'Revision'}
        {$_.Manufacturer -eq "ggOS"}{return 'ggOS'}
    }
    return $False
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

<#
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
#>
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
            if ($Original.$Key -ne $Patch.$Key){
                Write-Verbose "Changing $Key from $($Original.$Key) to $($Patch.$Key)"
            }
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
function New-Shortcut {
    param(
        [Switch]$Admin,
        [Switch]$Overwrite,
        [String]$LnkPath,
        [String]$TargetPath,
        [String]$Arguments,
        [String]$Icon
    )

    if ($Overwrite){
        if (Test-Path $LnkPath){
            Remove-Item $LnkPath
        }
    }

    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($LnkPath)
    $Shortcut.TargetPath = $TargetPath
    if ($Arguments){
        $Shortcut.Arguments = $Arguments
    }
    if ($Icon){
        $Shortcut.IconLocation = $Icon
    }

    $Shortcut.Save()
    if ((Get-Item $LnkPath).FullName -cne $LnkPath){
        Rename-Item $LnkPath -NewName (Get-Item $LnkPath).Name # Shortcut names are always underscore
    }

    if ($Admin){
    
        $bytes = [System.IO.File]::ReadAllBytes($LnkPath)
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($LnkPath, $bytes)
    }
}
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
# The prompt function itself isn't 
<# This function messes with the message that appears before the commands you type

# Turns:
PS D:\>
# into
TL D:\>

To obviously indicate TweakList has been imported

You can prevent this from happening
#>
$global:CSI = [char] 27 + '['
if (!$env:TL_NOPROMPT -and !$TL_NOPROMPT){
    function Prompt {
        "$CSI`97;7mTL$CSI`m $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    }
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
function Set-Choice { # Converts passed string to an array of chars
    param(
        [char[]]$Letters = "YN"
    )
    While ($Key -NotIn $Letters){
        [char]$Key = $host.UI.RawUI.ReadKey([System.Management.Automation.Host.ReadKeyOptions]'NoEcho, IncludeKeyDown').Character
        if (($Key -NotIn $Letters) -and !$IsLinux){
                [Console]::Beep(500,300)
        }
    }
    return $Key
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
function Test-Admin {
<#
.SYNOPSIS
Determines if the console is elevated

#>
    $identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal( $identity )
    return $principal.IsInRole( [System.Security.Principal.WindowsBuiltInRole]::Administrator )
}
function Write-Diff {
	param(
	[String]$Message,
	[Boolean]$Positivity,
	[String]$Term
	)
	$E = [char]0x1b # Ansi ESC character

	if ($Positivity){
		$Sign = '+'
		$Accent = "$E[92m"
		if (!$Term){
		$Term = "Enabled"
		}
	}
	elseif(!$Positivity){
		$Sign = '-'
		if (!$Term){
			$Term = "Removed"
		}
		$Accent = "$E[91m"
	}

	$Gray = "$E[90m"
	$Reset = "$E[0m"

	Write-Host "  $Gray[$Accent$Sign$Gray]$Reset $Term $Accent$Message"
 
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
	if (-Not(Get-Module -Name "Sophia Script (TL)" -Ea 0)){
		Import-Sophia
	}
	CortanaButton -Hide
	PeopleTaskbar -Hide
	TaskBarSearch -Hide
	TaskViewButton -Hide
	UnpinTaskbarShortcuts Edge, Store, Mail

	# Remove "Meet now" from the taskbar, s/o privacy.sexy
	Set-ItemProperty -Path "Registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Value 1
}
function Optimize-LunarClient {
    <#
    .SYNOPSIS
    Display Name: Optimize LunarClient
    Platform: Linux; Windows
    Category: Optimizations

    .DESCRIPTION
    Tunes a selected Lunar Client profile to your liking

    .PARAMETER Settings
    Specify which specific tweak you'd like applying on your profile
    #>
    [alias('optlc')]
    param(

        #//[HelpMessage("Set your lazy chunk load speed")]
        [ValidateSet(
            'highest',  
            'high',     
            'medium',   
            'low',      
            'lowest',   
            'off_van'   
            )]
        [String]$LazyChunkLoadSpeed = 'low',

        [ValidateSet(
            'Performance',
            'NoCosmetics',
            'MinimalViewBobbing',
            'No16xSaturationOverlay',
            'HideToggleSprint',
            'ToggleSneak',
            'DisableUHCMods',
            'FullBright',
            'CouleursPreset'    
        )]
        #// Gotta be put twice because mf cant handle variables in validate sets
        [Array]$Settings = (Invoke-Checkbox -Title "Select tweaks to apply" -Items @(
            'Performance'
            'NoCosmetics'
            'MinimalViewBobbing'
            'No16xSaturationOverlay'
            'HideToggleSprint'
            'ToggleSneak'
            'DisableUHCMods'
            'FullBright'
            'CouleursPreset'
        )),
       
        [String]
        $LCDirectory = "$HOME\.lunarclient",

        [Switch]$NoBetaWarning,
        [Switch]$KeepLCOpen,
        [Switch]$DryRun

        #//TODO: [Array]$Misc HideFoliage, NoEntityShadow, LCNametags, Clearglass, NoBackground, NoHypixelMods
    )
    
    if (-Not(Test-Path $LCDirectory)){
        Write-Host "Lunar Client's directory ($HOME\.lunarclient) does not exist (for the turbonerds reading this you can overwrite that with -LCDirectory"
    }
    if (!$NoBetaWarning){
        Write-Warning "This script may corrupt your Lunar Client profiles, continue at your own risk,`nyou're probably safer if you copy the folder located at $(Convert-Path $HOME\.lunarclient\settings\game)"
        pause
    }
    if (!$KeepLCOpen){
        while ((Get-Process -Name java?).MainWindowTitle -Like "Lunar Client*"){
            Write-Host "You must quit Lunar Client before running these optimizations (LC will overwrite them when it exits)" -ForegroundColor Red
            pause
        }
    }else{
        Write-Warning "You disabled the script from not running if Lunar Client is running, here be dragons!"
        Start-Sleep -Milliseconds 500
    }

    if (!$LazyChunkLoadSpeed -and ('Performance' -in $Settings)){$LazyChunkLoadSpeed = 'low'}

    $Manager = Get-Content "$LCDirectory\settings\game\profile_manager.json" -ErrorAction Stop | ConvertFrom-Json
    
    $Profiles = @{}
    ForEach($Profile in $Manager){
        $Profiles += @{ "$($Profile.DisplayName) ($($Profile.Name))" = $Profile}
    }

    Write-Host "Select a profile:"
    $Selection = Menu @([Array[]]'Create a new profile' + [Array[]]$Profiles.Keys)
    if ($Selection -in $Manager.name,$Manager.DisplayName){
        if ($VerbosePreference -eq 'Continue'){
            Write-Host "Error, Manager:`n`n" -ForegroundColor Red
            Write-Host ($Manager | ConvertTo-Json)
            return
            
        }
        return "A profile with the same name already exists!"
    }

    if ($Selection -eq 'Create a new profile'){
        
        $ProfileName = Read-Host "Enter a name for the new profile"
        New-Item -ItemType Directory -Path "$LCDirectory\settings\game\$ProfileName" -ErrorAction Stop | Out-Null
        Push-Location "$LCDirectory\settings\game\$ProfileName"
        ('general.json', 'mods.json', 'performance.json') | ForEach-Object {
            if (-Not(Test-Path ./$_)){Add-Content ./$_ -Value '{}'} # Empty json file 
        }
        Pop-Location
        $Selection = [PSCustomObject]@{

            name = $ProfileName
            displayName = $ProfileName
            active = $False
            default = $False
            iconName = 'crossed-swords'
            server = ''
        }
        $Manager += $Selection # Overwriting the string "Create a new profile" with the fresh one
        Set-Content -Path "$LCDirectory\settings\game\profile_manager.json" -Value ($Manager | ConvertTo-Json -Compress -Depth 99)
    }else{
        $Selection = $Profiles.$Selection
    }

    $ProfileDir = "$LCDirectory\settings\game\$($Selection.name)"
    ForEach($file in 'general','mods','performance'){ # Assigns $general, $mods and $performance variables
        Set-Variable -Scope Global -Name $file -Value (Get-Content "$ProfileDir\$file.json" -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
        if ($DryRun){
        Write-Host $file -ForegroundColor Red
        (Get-Variable -Name $file).Value | ConvertTo-Json
        }
    }
    
    $Presets = @{
        All = @{
            general = @{
                shift_effects_bl         = $false
                achievements_bl	         = $false
                compact_menu_bl          = $true
                modernKeybindHandling_bl = $true
                borderless_fullscreen_bl = $true
                trans_res_pack_menu_bg_bl = $true
            }
            mods = @{
                chat = @{
                    options = @{
                        chat_bg_opacity_nr = "0.0"
                    }
                }
                scoreboard = @{
                    options = @{
                        numbers_bl = $true
                    }
                }
            }
        }
        CouleursPreset = @{
            mods = @{
                scoreboard = @{
                    seen = $True
                    x = 2 # Moves scoreboard 2 pixels to the right
                }
                potioneffects = @{
                    seen = $True
                    position = 'bottom_left'
                    y = -246.5 # Middle left
                }
                saturation_hud_mod = @{
                    seen = $True
                    saturation_hud_mod_enabled_bl = $True
                    position     = 'bottom_right' # Just right to the last hunger bar
                    x            = -289
                    y            = -37
                    options = @{
                        scale_nr          = 1.5 # Yellow
                        text_clr_nr       = @{value=-171}
                        background_clr_nr = @{value=0}
                    }
                }
                zoom = @{
                    seen = $True
                    options = @{
                        zoom_kblc         = 'KEY_X'
                    }
                }
                bossbar = @{
                    seen = $True
                    bossbar_enabled_bl = $False
                }
            }
        }
        Performance = @{
            general = @{
                friend_online_status_bl	= $false
            }
            performance = @{
                lazy_chunk_loading	= $LazyChunkLoadSpeed
                ground_arrows_bl    = $false
                stuck_arrows_bl     = $false
                hide_skulls_bl      = $true
                hide_foliage_bl     = $true
            }
        }
        NoCosmetics = @{
            general = @{
                renderClothCloaks_bl         = $false
                render_cosmetic_particles_bl = $false
                backpack_bl                  = $false
                dragon_wings_bl              = $false
                pet_bl                       = $false
                glasses_bl                   = $false
                bandanna_bl                  = $false
                mask_bl                      = $false
                belts_bl                     = $false
                neckwear_bl                  = $false
                bodywear_bl                  = $false
                hat_bl                       = $false
                render_emotes_bl             = $false
                render_emote_particles_bl    = $false
                cloak_bl                     = $false
                show_hat_above_helmet_bl     = $false
                show_over_chestplate_bl      = $false
                show_over_leggings_bl        = $false
                show_over_boots_bl           = $false
                scale_hat_with_skinlayer_bl  = $false
            }
        }
        MinimalViewBobbing = @{
            general = @{
                minimal_viewbobbing_bl = $true
            }
        }
        No16xSaturationOverlay = @{
            mods = @{
                saturation_mod = @{
                    options = @{
                        show_saturation_overlay_bl=$False
                    }
                }
            }
        }
        HideToggleSprint = @{
            mods = @{
                toggleSneak = @{
                     options = @{
                         showHudText_bl = $false
                     }
                }
            }
        }
        ToggleSneak = @{
            mods = @{
                toggleSneak = @{
                    options = @{
                        toggle_sneak_bl = $true
                    }
                }
            }
        }
        DisableUHCMods = @{
            mods = @{
                waypoints = @{
                    waypoints_enabled_bl = $false
                }
                directionhud = @{
	                directionhud_enabled_bl = $false
                }
                coords = @{
	                coords_enabled_bl = $false
                }                
                armorstatus = @{
	                armorstatus_enabled_bl = $false
                }
            }
        }
        FullBright = @{
            mods = @{
                lighting = @{
                    lighting_enabled_bl = $true
                    options = @{
                        full_bright_bl	= $true
                    } 
                }
            }
        }

    }
        # Whatever you do that's highly recommended :+1:
    $general = Merge-Hashtables -Original $general -Patch $Presets.All.general
    $mods = Merge-Hashtables -Original $mods -Patch $Presets.All.mods
    Write-Diff "recommended settings (compact mods, fast chat).." -Positivity $True -Term "Setting up"

    if ('Performance' -in $Settings){
        $general = Merge-Hashtables -Original $general -Patch $Presets.Performance.general
        $performance = Merge-Hashtables -Original $performance -Patch $Presets.Performance.performance
        Write-Diff -Message "notifications from LC friends getting on (causes massive FPS drop)"
        Write-Diff -Positivity $True -Message "lazy chunk loading at speed $LazyChunkLoadSpeed"
        Write-Diff -Message "ground arrows"
        Write-Diff -Message "player/mob skulls"
        Write-Diff -Message "foliage (normal/tall grass)"
    }
    if ('NoCosmetics' -in $Settings){
        $general = Merge-Hashtables -Original $general -Patch $Presets.NoCosmetics.general
        ForEach($CosmeticRemoved in @(
            "cloth cloaks" 
            "cosmetic particles" 
            "backpacks" 
            "pets"
            "dragon wings"
            "bandannas"
            "masks"
            "belts"
            "neckwears"
            "bodywears"
            "hats"
            "emotes rendering"
            "emote particles rendering"
            "cloaks"
        )){
            Write-Diff -Message $CosmeticRemoved -Term "Disabled"
        }

    }
    if ('MinimalViewBobbing' -in $Settings){
        $general = Merge-Hashtables -Original $general -Patch $Presets.MinimalViewBobbing.general
        Write-Diff -Positivity $True -Message "minimal view bobbing"
    }
    if ('No16xSaturationOverlay' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.No16xSaturationOverlay.mods
        Write-Diff -Positivity $False -Message "16x saturation hunger bar overlay"
    }
    if ('HideToggleSprint' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.HideToggleSprint.mods
        Write-Diff -Positivity $False -Term "Hid" -Message "ToggleSprint HUD"
    }
    if ('ToggleSneak' -in $Settings){
        $mods = Merge-Hashtables -Original $mods $Presets.ToggleSneak.mods
        Write-Diff -Positivity $True -Message "ToggleSneak"
    }
    if ('DisableUHCMods' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.DisableUHCMods.mods
        Write-Diff -Positivity $False -Term "Disabled" -Message "Waypoints mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "DirectionHUD mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "Coordinates mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "ArmorStatus mod"
    }
    if ('FullBright' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.FullBright.mods
        Write-Diff -Term "Added" -Positivity $true -Message "Fullbright (disable shaders before restarting)"
    }
    if ('CouleursPreset' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.CouleursPreset.mods
    }

    ForEach($file in 'general','mods','performance'){ # Assigns $general, $mods and $performance variables
        if ($DryRun){
            Write-Host $file -ForegroundColor Red
            (Get-Variable -Name $file).Value
        }else{
            ConvertTo-Json -Depth 99 -Compress -InputObject (Get-Variable -Name $file).Value -ErrorAction Stop | Set-Content "$ProfileDir\$file.json" -ErrorAction Stop
        }
    }

}
function Optimize-OBS {
    <#
    .SYNOPSIS
    Display Name: Optimize OBS
    Platform: Linux; Windows
    Category: Optimizations

    .DESCRIPTION
    Tune your OBS for a specific usecase in the snap of a finger!

    .PARAMETER Encoder
    Which hardware type you wish to record with
    NVENC: NVIDIA's Fastest encoder, it lets you record in hundreds of FPS easily
    AMF: AMD GPUs/Integrated GPUs encoder, not as good as NVENC but can still get out ~240FPS at most
    QuickSync: Intel's GPU encoder, worst out of the three, note this is H264, not the new fancy but slow AV1
    x264: Encoding using your CPU, slow but efficient, only use if necessary/you know what you're doing

    .PARAMETER OBS64Path
    If you've got a portable install or something, pass in the main OBS binary's path here

    #>
    [alias('optobs')]
    param(
        [ValidateSet('x264','NVENC','AMF','QuickSync')]
        [String]$Encoder,
        
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [String]$OBS64Path, #//Indicate your OBS installation by passing -OBS64Path "C:\..\bin\64bit\obs64.exe"

        [ValidateSet('HighPerformance')]
        [String]$Preset = 'HighPerformance'

    )

    if (!$Encoder){
        $Encoders = @{
            "NVENC (NVIDIA GPUs)" = "NVENC"
            "AMF (AMD GPUs)" = "AMF"
            "QuickSync (Intel iGPUs)" = "QuickSync"
            "x264 (CPU)" = "x264"
        }
        Write-Host "Select what OBS will use to record (use arrow keys and press ENTER to confirm)"
        $Key = Menu ([Collections.ArrayList]$Encoders.Keys)
        $Encoder = $Encoders.$Key # Getting it back from 
    }

    $OBSPatches = @{
        HighPerformance = @{
            NVENC = @{
                basic = @{
                    AdvOut = @{
                        RecEncoder = 'jim_nvenc'
                    }
                }
                recordEncoder = @{
                    bf=0
                    cqp=18
                    multipass='disabled'
                    preset2='p2'
                    profile='main'
                    psycho_aq='false'
                    rate_control='CQP'
                }
            }
            AMF = @{
                Basic = @{
                    ADVOut = @{
                        RecQuality='Small'
                        RecEncoder='h265_texture_amf'
                        FFOutputToFile='true'
                    }
                }
                recordEncoder = @{
                    'cqp' = 20
                    preset = 'speed'
                    rate_control = 'CQP'
                    ffmpeg_opts = "MaxNumRefFrames=4 HighMotionQualityBoostEnable=1"
                }
            }
            QuickSync = @{

                basic = @{
                    AdvOut = @{
                        RecEncoder = 'obs_qsv11'
                    }
                }
                recordEncoder = @{
                    enhancements = 'false'
                    target_usage = 'speed'
                    bframes = 0
                    rate_control = 'ICQ'
                    bitrate = 16500
                    icq_quality = 18
                    keyint_sec = 2
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
 Search OBS -> Right click it
 Open file location in Explorer ->
 Open file location again if it's a shortcut ->
 Shift right click obs64.exe -> Copy as path
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

    if (!$IsLinux -or !$IsMacOS){
        [Version]$CurVer = (Get-Item $OBS64Path).VersionInfo.ProductVersion
        if ($CurVer -lt [Version]"28.1.0"){
            Write-Warning @"
It is strongly advised you update OBS before continuing (for compatibility with new NVENC/AMD settings)

Detected version: $CurVer
obs64.exe path: $OBS64Path
pause
"@
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
    try {
        $Basic = Get-IniContent "$OBSProfile\basic.ini" -ErrorAction Stop
    } catch {
        Write-Warning "Failed to get basic.ini from profile folder $OBSProfile"
        $_
        return
    }
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
        [ValidateSet('Smart','Lowest','CouleursPreset')]
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

    CouleursPresets = @{
        options = @{
            'key_key.hotbar.5' = 19
            'key_key.hotbar.6' = 20
            'key_key.hotbar.7' = 33
            'key_key.hotbar.8' = 34
            'key_key.hotbar.9' = 0
            chatScale      = 0.8
            chatWidth      = 0.65
            guiScale       = 3
            renderDistance = 7
            maxFps         = 260
            chatOpacity    = 0.25
            enableVsync    = $False
            pauseOnLostFocus = $False
        }
    }

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
if (Test-Path "$CustomDirectory\optionsLC.txt"){
    $Hash = (Get-Content "$CustomDirectory\optionsLC.txt") -Replace ',"maxFps":"260"','' | ConvertFrom-Json
}
$Hash = Merge-Hashtables -Original $Hash -Patch $Presets.$Preset.optionsof
$Hash = Merge-Hashtables -Original $Hash -Patch $Presets.$Preset.options
$Hash.maxFPS = 260
Set-Content "$CustomDirectory\optionsLC.txt" -Value (ConvertTo-Json $Hash) -Force

}
function Get-TLShell {
    param(
        [switch]$Offline,
        [switch]$DontOpen
        )
    
    $WR = "$env:LOCALAPPDATA\Microsoft\WindowsApps" # I've had the habit of calling this folder WR
                                                    # because it's the only folder I know that is added to path
                                                    # that you don't need perms to access.

if ($Offline){
    
    try {
        $Master = Invoke-RestMethod -UseBasicParsing https://raw.githubusercontent.com/couleur-tweak-tips/TweakList/master/Master.ps1
    } catch {
        Write-Host "Failed to get Master.ps1 from TweakList GitHub" -ForegroundColor DarkRed
        Write-Output "Error: $($Error[0].ToString())"
        return
    }
    Set-Content "$WR/TLSOff.cmd" -Value @'
<# : batch portion
@echo off
powershell.exe -noexit -noprofile -noexit -command "iex (${%~f0} | out-string)"
: end batch / begin powershell #>
Write-Host "TweakList Shell " -Foregroundcolor White -NoNewLine
Write-Host "(Offline)" -Foregroundcolor DarkGray -NoNewLine
Write-Host " - dsc.gg/CTT" -Foregroundcolor White -NoNewLine

'@
    $Batch = Get-Item  "$WR/TLSOff.cmd"
    Add-Content $Batch -Value $Master
    if (!$DontOpen){
        explorer.exe /select,`"$($Batch.FullName)`"
    }

}else{


    
    if ($WR -NotIn $env:PATH.Split(';')){
        Write-Error "`"$env:LOCALAPPDATA\Microsoft\WindowsApps`" is not added to path, did you mess with Windows?"
        return
    }else{
        $TLS = "$WR\TLS.CMD"
        Set-Content -Path $TLS -Value @'
@echo off
title TweakList Shell
if /I "%1" == "wr" (explorer "%~dp0" & exit)
if /I "%1" == "so" (set sophiaflag=Write-Host 'Importing Sophia Script..' -NoNewLine -ForegroundColor DarkGray;Import-Sophia)

fltmc >nul 2>&1 || (
    echo Elevating to admin..
    PowerShell.exe -NoProfile Start-Process -Verb RunAs ' %0' 2> nul || (
        echo Failed to elevate to admin, launch CMD as Admin and type in "TL"
        pause & exit 1
    )
    exit 0
)

powershell.exe -NoProfile -NoLogo -NoExit -Command ^
"if ($PWD.Path -eq \"$env:WINDIR\system32\"){cd $HOME} ;^
[System.Net.ServicePointManager]::SecurityProtocol='Tls12' ;^
Write-Host 'Invoking TweakList.. ' -NoNewLine -ForegroundColor DarkGray;^
iex(irm tl.ctt.cx);^
%SOPHIAFLAG%;^
Write-Host \"`rTweakList Shell - dsc.gg/CTT                  `n\" -Foregroundcolor White"
'@ -Force
    }
    $ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\TweakList Shell.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.IconLocation = (Get-Command powershell.exe).Source + ",0"
    $Shortcut.TargetPath = "$WR\TLS.CMD"
    $Shortcut.Save()

    # Got this from my old list of snippets, originally found this on StackOverflow, forgot link
    $bytes = [System.IO.File]::ReadAllBytes($ShortCutPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 # Set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes($ShortcutPath, $bytes)

    Write-Host "You can now type 'TLS' in Run (Windows+R) to launch it, or from your start menu"
    if (!$DontOpen){
        & explorer.exe /select,`"$("$WR\TLS.CMD")`"
    }
    
    
}
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
        [Switch]$GetTemplates = $false 
    )       # Skip Voukoder installation and just get to the template selector

    if ($PSEdition -eq 'Core'){
        return "Install-Voukoder is only available on Windows PowerShell 5.1 (use of Get-Package)."
    }       # Get-Package is used for Windows programs, on PowerShell 7 (core) it's for PowerShell modules

    if (!$GetTemplates){

        $LatestCore = (Invoke-RestMethod https://api.github.com/repos/Vouk/voukoder/releases/latest)[0]
            # Get the latest release manifest from GitHub's API

        if (($tag = $LatestCore.tag_name) -NotLike "*.*"){
            $tag += ".0" # E.g "12" will not convert to a version type, "12.0" will
        }
        [Version]$LatestCoreVersion = $tag

        $Core = Get-Package -Name "Voukoder*" -ErrorAction Ignore | # Find all programs starting with Voukoder
            Where-Object Name -NotLike "*Connector*" # Exclude connectors

        if ($Core){

            if ($Core.Length -gt 1){
                $Core
                Write-Host "Multiple Voukoder Cores detected (or bad parsing?)" -ForegroundColor Red
                return
            }

            $CurrentVersion = [Version]$Core.Version
            if ($LatestCoreVersion -gt $CurrentVersion){ # then an upgrade is needed
                "Updating Voukoder Core from version $CurrentVersion to $LatestCoreVersion"
                Start-Process -FilePath msiexec -ArgumentList "/qb /x {$($Core.TagId)}" -Wait -NoNewWindow
                    # Uses msiexec to uninstall the program
                $Upgraded = $True
            }
        }

        if (!$Core -or $Upgraded){

            $DriverVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}_Display.Driver" -ErrorAction Ignore).DisplayVersion
            if ($DriverVersion -and $DriverVersion -lt 520.00){ # Oldest NVIDIA version capable
                Write-Warning "Outdated NVIDIA Drivers detected ($DriverVersion), you may not be able to encode (render) using NVENC util you update them."
                pause
            }

            "Downloading and installing Voukoder Core.."
            $CoreURL = $LatestCore[0].assets[0].browser_download_url
            curl.exe -# -L $CoreURL -o"$env:TMP\Voukoder-Core.msi"
            msiexec /i "$env:TMP\Voukoder-Core.msi" /passive    
        }

        filter ConnectorVer {$_.Trim('.msi').Trim('.zip').Split('-') | Select-Object -Last 1}
            # .zip for Resolve's


    # Following block generates a hashtable of all of the latest connectors

        $Tree = (Invoke-RestMethod 'https://api.github.com/repos/Vouk/voukoder-connectors/git/trees/master?recursive=1').Tree
            # Gets all files from the connectors repo, which contain all filepaths
        $Connectors = [Ordered]@{}
        ForEach($NLE in 'vegas','vegas18','vegas19','vegas20','aftereffects','premiere','resolve'){
            # 'vegas' is for older versions
            switch ($NLE){
                vegas{
                    $Pattern = "*vegas-connector-*"
                    break # needs to stop here, otherwise it would overwrite it the next match
                }
                {$_ -Like "vegas*"}{
                    $Pattern = "*connector-$_*"
                }
                default {
                    $Pattern = "*$NLE-connector*"
                }
            }

            $LCV = $Tree.path | # Short for LatestConnectorVersion
            Where-Object {$_ -Like $Pattern} | # Find all versions of all matching connectors
            ForEach-Object {[Version]($_ | ConnectorVer)} | # Parse it's version using the filter
            Sort-Object -Descending | Select-Object -First 1 # Sort then select only the latest

            $Path = $Tree.path | Where-Object {$_ -Like "$Pattern*$LCV*.*"} # Get the absolute path with the latest version
            $Connectors += @{$NLE = "https://github.com/Vouk/voukoder-connectors/raw/master/$Path"}
            Remove-Variable -Name NLE
        }

        $Processes = @(
            'vegas*'
            'Adobe Premiere Pro'
            'AfterFX'
            'Resolve'
        )
        Write-Host "Looking for $($Processes -Join ', ').."

        While(!(Get-Process $Processes -ErrorAction Ignore)){
            Write-Host "`rScanning for any opened NLEs (video editors), press any key to refresh.." -NoNewline -ForeGroundColor Green
            Start-Sleep -Seconds 1
        }
        ''
        function NeedsConnector ($PackageName, $Key){
            # Key is to get the $Connector URL
            
            $CurrentConnector = (Get-Package -Name $PackageName -ErrorAction Ignore)
            if ($CurrentConnector){
                [Version]$CurrentConnectorVersion = $CurrentConnector.Version
                [Version]$LatestConnector = $Connectors.$key | ConnectorVer
                if ($LatestConnector -gt $CurrentConnectorVersion){
                    "Upgrading $PackageName from $CurrentConnectorVersion to $LatestConnector"
                    Start-Process -FilePath msiexec -ArgumentList "/qb /x {$($CurrentConnector.TagId)}" -Wait -NoNewWindow
                    return $True
                }
            }
            return $False
        }
        $NLEs = Get-Process $Processes -ErrorAction Ignore
        ForEach($NLE in $NLEs){
            switch (Split-Path $NLE.Path -Leaf){


                {$_ -in 'vegas180.exe', 'vegas190.exe','vegas200.exe'} {
                    Write-Verbose "Found VEGAS18+"

                    $KeyName = $_.TrimEnd("0.exe")
                    if (NeedsConnector -PackageName 'Voukoder connector for VEGAS' -Key $KeyName){
                        continue
                    }
                    $Directory = Split-Path $NLE.Path -Parent
                    curl.exe -# -L $Connectors.vegas18 -o"$env:TMP\Voukoder-Connector-$($KeyName.ToUpper()).msi"
                    msiexec /i "$env:TEMP\Voukoder-Connector-VEGAS18.msi" /qb "VEGASDIR=`"$Directory`""
                    continue
                }



                {$_ -Like 'vegas*.exe'}{
                    Write-Verbose "Found old VEGAS"
                    Write-Host "Old VEGAS connector installation may fail if you already have a connector for newer VEGAS versions"
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
                    Write-Warning "Voukoder's connector for Resolve is ONLY FOR IT'S PAID `"Studio`" VERSION"
                    pause
                    $IOPlugins = "$env:ProgramData\Blackmagic Design\DaVinci Resolve\Support\IOPlugins"
                    if (-Not(Test-Path $IOPlugins)){
                        New-Item -ItemType Directory -Path $IOPlugins
                    }
                    elseif (Test-Path "$IOPlugins\voukoder_plugin.dvcp.bundle"){
                        if (-Not(Get-Boolean "Would you like to reinstall/update the Voukoder Resolve plugin? (Y/N)")){continue}
                        Remove-Item "$IOPlugins\voukoder_plugin.dvcp.bundle" -Force -Recurse
                    }
                    curl.exe -# -L $Connectors.Resolve -o"$env:TMP\Voukoder-Connector-Resolve.zip"
                    Remove-Item "$env:TMP\Voukoder-Connector-Resolve" -Recurse -Force -ErrorAction Ignore
                    $ExtractDir = "$env:TMP\Voukoder-Connector-Resolve"
                    Expand-Archive "$env:TMP\Voukoder-Connector-Resolve.zip" -Destination $ExtractDir
                    Copy-Item "$ExtractDir\voukoder_plugin.dvcp.bundle" $IOPlugins
                    Write-Warning "If connection failed you should find instructions in $ExtractDir\README.txt"
                }
            }
        }
    }else{
        $AvailableNLETemplates = @{
            "Vegas Pro" = "vegas200.exe"
            "Premiere Pro" = "Adobe Premiere Pro.exe"
            "After Effects" = "AfterFX.exe"
        }
        $NLE = Menu -menuItems $AvailableNLETemplates.Keys
        $NLE = $AvailableNLETemplates.$NLE
    }

        # Converts 
        # https://cdn.discordapp.com/attachments/969870701798522901/972541638578667540/HEVC_NVENC_Upscale.sft2
        # To hashtable with key "HEVC NVENC + Upscale" and val the URL

    filter File2Display {[IO.Path]::GetFileNameWithoutExtension((((($_ | Split-Path -Leaf) -replace '_',' ' -replace " Upscale", " + Upscale")) -replace '  ',' '))}
                         # Get file ext    Put spaces instead of _       Format Upscale prettily  Remove extension
    $VegasTemplates = @(

        'https://cdn.discordapp.com/attachments/1039599872703213648/1039599904873517106/HEVC_NVENC_Upscale.sft2'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039599905175502929/HEVC_NVENC.sft2'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039599904609288255/HEVC_NVENC__Upscale.sft2'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039599904353419284/H264_NVENC.sft2'
        'https://cdn.discordapp.com/attachments/969870701798522901/972541639346225264/x265_Upscale.sft2'
        'https://cdn.discordapp.com/attachments/969870701798522901/972541639560163348/x265.sft2'
        'https://cdn.discordapp.com/attachments/969870701798522901/972541638943596574/x264_Upscale.sft2'
        'https://cdn.discordapp.com/attachments/969870701798522901/972541639128129576/x264.sft2'
        # 'https://cdn.discordapp.com/attachments/969870701798522901/972541638578667540/HEVC_NVENC_Upscale.sft2'
        # 'https://cdn.discordapp.com/attachments/969870701798522901/972541638733885470/HEVC_NVENC.sft2'
        # 'https://cdn.discordapp.com/attachments/969870701798522901/972541639744688198/H264_NVENC_Upscale.sft2'
        # 'https://cdn.discordapp.com/attachments/969870701798522901/972541638356389918/H264_NVENC.sft2'
        ) | ForEach-Object {
        [Ordered]@{($_ | File2Display) = $_}
    }

    $PremiereTemplates = @(
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039609690025369690/HEVC_NVENC__Upscale.epr'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039609690369298432/HEVC_NVENC.epr'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039609691992498218/H264_NVENC__Upscale.epr'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039609692277706902/H264_NVENC.epr'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039609690688061490/x264__Upscale.epr'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039609690964893706/x264.epr'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039609691380125827/x265__Upscale.epr'
        'https://cdn.discordapp.com/attachments/1039599872703213648/1039609691682111548/x265.epr'
    ) | ForEach-Object {
        [Ordered]@{($_ | File2Display) = $_}
    }

    switch([String]$NLE){

        {($NLE.Path | Split-Path -Leaf).StartsWith('vegas')}{

            $NLETerm = "Vegas"
            $TemplatesFolder = "$env:APPDATA\VEGAS\Render Templates\voukoder"

            if (-Not(Test-Path $TemplatesFolder)){
                New-Item -ItemType Directory -Path $TemplatesFolder -Force | Out-Null
            }

            $SelectedTemplates =  Invoke-Checkbox -Items $VegasTemplates.Keys -Title "Select render templates to install"

            ForEach ($Template in $SelectedTemplates){
                if (Test-Path ($TPPath = "$TemplatesFolder\$Template.sft2")){
                    Remove-Item $TPPath -Force
                }
                curl.exe -# -sSL $VegasTemplates.$Template -o"$TPPath"
            }
        }



        'Adobe Premiere Pro.exe'{
            
            $NLETerm = 'Premiere Pro'
            $TemplatesFolder = "$env:USERPROFILE\Documents\Adobe\Adobe Media Encoder\12.0\Presets"

            if (-Not(Test-Path $TemplatesFolder)){
                New-Item -ItemType Directory -Path $TemplatesFolder -Force | Out-Null
            }

            $SelectedTemplates =  Invoke-Checkbox -Items $PremiereTemplates.Keys -Title "Select render templates to install"

            ForEach ($Template in $SelectedTemplates){
                if (Test-Path ($TPPath = "$TemplatesFolder\$Template.epr")){
                    Remove-Item $TPPath -Force
                }
                curl.exe -# -sSL $PremiereTemplates.$Template -o"$TPPath"
            }
        
        }




        'AfterFX.exe'{
            $NLETerm = 'After Effects'

            "Opening a tutorial in your browser and downloading the AE templates file.."
            Start-Sleep -Seconds 2
            if (-Not(Test-Path ($TPDir = "$env:TMP\AE_Templates"))){
                New-Item -ItemType Directory -Path $TPDir -Force | Out-Null
            }
            curl.exe -# -sSL https://cdn.discordapp.com/attachments/1039599872703213648/1039614649638858772/CTT_AE_VOUKODER_TEMPLATES.aom -o"$TPDir\CTT_AE_VOUKODER_TEMPLATES.aom"

            Start-Process -FilePath explorer.exe -ArgumentList "/select,`"$TPDir\CTT_AE_VOUKODER_TEMPLATES.aom`""
            $Tutorial = 'https://i.imgur.com/XCaJGoV.mp4'
            try {
                Start-Process $Tutorial
            } catch { # If the user does not have any browser
                "Tutorial URL: $Tutorial" 
            }
        }



        default{
            Write-Host "Your video editor ($([String]$NLE)) does not have any pre-made templates for me to propose you" -ForegroundColor Red
            $NLETerm = "your video editor"
        }
    }
    Write-Output "Installation script finished, restart $NLETerm to refresh your render templates."

}
function Invoke-SmoothiePost {
    param(
        [String]
        [ValidateScript({
            Test-Path -Path (Get-Item $_) -PathType Container -ErrorAction Stop
        })]
        $CustomDir
    )
    # DIR is the variable used by Scoop, hence why I'm using a separate name
    if ($CustomDir -and !$DIR){
        if (!(Test-Path "$CustomDir\Smoothie") -And !(Test-Path "$CustomDir\VapourSynth")){
            Write-Host "The folder you gave needs to contain the folders 'Smoothie' and 'VapourSynth', try the right path"
        }else{
            $DIR = (Get-Item $CustomDir).FullName
        }
    }
    if (!$DIR){return "This script is suppose to be ran by Scoop after it's intallation, not manually"}

    $rc = (Get-Content "$DIR\Smoothie\settings\recipe.yaml" -ErrorAction Stop) -replace ('H264 CPU',(Get-EncodingArgs -EzEncArgs))

    if ($valid_args -like "H* CPU"){$rc = $rc -replace ('gpu: true','gpu: false')}

    Set-Content "$DIR\Smoothie\settings\recipe.ini" -Value $rc

    if (Get-Command wt.exe -Ea Ignore){$term = Get-Path wt.exe}
    else{$term = Get-Path conhost.exe}

    Get Scoop

    $SendTo = [System.Environment]::GetFolderPath('SendTo')
    $Scoop = Get-Command Scoop | Split-Path | Split-Path
    $SA = [System.IO.Path]::Combine([Environment]::GetFolderPath('StartMenu'), 'Programs', 'Scoop Apps')

    if (-Not(Test-Path $SA)){ # If not using Scoop
        $SA = [System.IO.Path]::Combine([Environment]::GetFolderPath('StartMenu'), 'Programs')
    }

    Set-Content "$Scoop\shims\sm.shim" -Value @"
path = "$DIR\VapourSynth\python.exe"
args = "$DIR\Smoothie\src\main.py"
"@
    if (-Not(Test-Path "$Scoop\shims\sm.exe")){
        Copy-Item "$Scoop\shims\7z.exe" "$Scoop\shims\sm.exe"
    }


    $Parameters = @{
        Overwrite = $True
        LnkPath = "$Scoop\shims\rc.lnk"
        TargetPath = "$DIR\Smoothie\settings\recipe.yaml"
    }
    New-Shortcut @Parameters


    $Parameters = @{
        Overwrite = $True
        LnkPath = "$SA\Smoothie Recipe.lnk"
        TargetPath = "$DIR\Smoothie\settings\recipe.yaml"
    }
    New-Shortcut @Parameters

    $Parameters = @{
        Overwrite = $True
        LnkPath = "$SA\Smoothie.lnk"
        TargetPath = $term
        Arguments = "`"$DIR\VapourSynth\python.exe`" `"$DIR\Smoothie\src\main.py`" -cui"
        Icon = "$DIR\Smoothie\src\sm.ico"
    }
    New-Shortcut @Parameters
    
    $Parameters = @{
        Overwrite = $True
        LnkPath = "$SendTo\Smoothie.lnk"
        TargetPath = $term
        Arguments = "`"$DIR\VapourSynth\python.exe`" `"$DIR\Smoothie\src\main.py`" -cui -input"
        Icon = "$DIR\Smoothie\src\sm.ico"

    }
    New-Shortcut @Parameters

}
function 4K-Notifier {
    param(
        [Parameter(Mandatory)]
        [String]$Video,
        [int]$Timeout = 30
    )
    if (!$Video){
        $Video = Read-Host "Pleaste paste in the URL of the video you'd like to wait for until it hits 4K"
    }
if (Get-Command yt-dlp -Ea 0){
    $ytdl = (Get-Command yt-dlp).Source
}elseif(Get-Command youtube-dl -Ea 0){
    $ytdl = (Get-Command youtube-dl).Source
}else{
    return @"
Nor YouTube-DL or yt-dlp are installed or added to the path, please run the following command to install it:
iex(irm tl.ctt.cx);Get-ScoopApp main/yt-dlp
"@
}
''
$Finished = $null
$Attempt = 0
While (!$Finished){
    $Attempt++
    $Response = & $ytdl -F $Video
    if ($Response | Where-Object {$PSItem -Like "*3840x2160*"}){
        $Finished = $True
    }else{
        Write-Host "`rYour video has not been encoded to 4K, trying again (attempt no.$attempt) in $Timeout seconds.." -NoNewLine 
        Start-Sleep -Seconds $Timeout
        Write-Host "`rTrying again..                                                       " -NoNewLine -ForegroundColor Red
        continue
    }
}
Set-Clipboard -Value $Video
Write-Host @"

YouTubed finished processing your video, it's URL has been copied to your clipboard:
$Video
"@ -ForegroundColor Green
1..3 | ForEach-Object{
    [Console]::Beep(500,300)
    Start-Sleep -Milliseconds 100
}
}
function Moony2 {
    param(
        [Switch]$NoIntro,
        [Int]$McProcessID
    )
    $LaunchParameters = @{} # Fresh hashtable that will be splat with Start-Process

    if (!$NoIntro){
    Write-Host @'
If you're used to the original Moony, this works a little differently,

What you just runned lets you create a batchfile from your current running game
that you can launch via a single click or even faster: via Run (Windows +R)

Please launch your Minecraft (any client/version) and press ENTER on your keyboard
once you're ready for it to create the batchfile
'@
    Pause
    }

    # java? is regex for either java or javaw
    if (-Not(Get-Process java?)){
        Write-Host "There was no processes with the name java or javaw"
        pause
        Moony -NoIntro
        return
    }else{
        $ProcList = Get-Process -Name java?
        if ($ProcList[1]){ # If $Procs isn't the only running java process
                $Selected = Menu $ProcList.MainWindowTitle
                $Proc = Get-Process | Where-Object {$_.MainWindowTitle -eq ($Selected)} # Crappy passthru
                if ($Proc[1]){ # unlikely but w/e gotta handle it
                    Write-Host "Sorry my code is bad and you have multiple processes with the name $($Proc.MainWindowTitle), GG!"
                }
        }else{$Proc = $ProcList} # lmk if theres a smarter way
    }
    $WinProcess = Get-CimInstance -ClassName Win32_Process | Where-Object ProcessId -eq $Proc.Id
    $JRE = $WinProcess.ExecutablePath
    $Arguments = $WinProcess.CommandLine.Replace($WinProcess.ExecutablePath,'')
    if (Test-Path "$HOME\.lunarclient\offline\multiver"){
        $WorkingDirectory = "$HOME\.lunarclient\offline\multiver"

    }else{
            # This cumbersome parse has been split in 3 lines, it just gets the right version from the args
        $PlayedVersion = $Arguments.split(' ') |
        Where-Object {$PSItem -Like "1.*"} |
        Where-Object {$PSITem -NotLike "1.*.*"} |
        Select-Object -Last 1
        $WorkingDirectory = "$HOME\.lunarclient\offline\$PlayedVersion"
    }
    if ($Arguments -NotLike "* -server *"){
        Write-Host @"
Would you like this script to join a specific server right after it launches?

If so, type the IP, otherwise just leave it blank and press ENTER
"@  
        $ServerIP = Read-Host "Server IP"
        if ($ServerIP -NotIn '',$null){
            $Arguments += " -server $ServerIP"
        }
    }

    $InstanceName = Read-Host "Give a name to your Lunar Client instance, I recommend making it short without spaces"
    if ($InstanceName -Like "* *"){
        $InstanceName = Read-Host "Since there's a space in your name, you won't be able to call it from Run (Windows+R), type it again if you are sure"
    }

    Set-Content "$env:LOCALAPPDATA\Microsoft\WindowsApps\$InstanceName.cmd" @"
@echo off
cd /D "$WorkingDirectory"
start "$JRE" $Arguments
if %ERRORLEVEL% == 0 (exit) else (pause)
"@
    Write-Host "Your $InstanceName instance should be good to go, try typing it's name in the Run window (Windows+R)" -ForegroundColor Green
    return

}
function Remove-DesktopShortcuts ([Switch]$ConfirmEach){
    
    if($ConfirmEach){
        Get-ChildItem -Path "$HOME\Desktop" | Where-Object Extension -eq ".lnk" | Remove-Item -Confirm
    }else{
        Get-ChildItem -Path "$HOME\Desktop" | Where-Object Extension -eq ".lnk" | Remove-Item
    }
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
function Set-Win32PrioritySeparation ([int]$DWord){

    $Path = 'REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl'
    $current = (Get-ItemProperty $Path).Win32PrioritySeparation

    Set-ItemProperty -Path ($Path).Win32PrioritySeparation -Value $Value -Type DWord -Force -ErrorAction Inquire

    Write-Verbose "Set-Win32ProritySeparation: Changed from $current to $((Get-ItemProperty $Path).Win32PrioritySeparation)"

}

function Add-ContextMenu {
    #! TODO https://www.tenforums.com/tutorials/69524-add-remove-drives-send-context-menu-windows-10-a.html
    param(
        [ValidateSet(
            'SendTo',
            'TakeOwnership',
            'OpenWithOnBatchFiles',
            'DrivesInSendTo',
            'TakeOwnership'
            )]
        [Array]$Entries
    )

    if ('SendTo' -in $Entries){
        New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo -Name "(default)" -PropertyType String -Value "{7BA4C740-9E81-11CF-99D3-00AA004AE837}" -Force
    }

    if ('DrivesInSendTo' -in $Entries){
        Set-ItemProperty "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoDrivesInSendToMenu -Value 0
    }


    if ('OpenWithOnBatchFiles' -in $Entries){
        New-Item -Path "Registry::HKEY_CLASSES_ROOT\batfile\shell\Open with\command" -Force
        New-Item -Path "Registry::HKEY_CLASSES_ROOT\cmdfile\shell\Open with\command" -Force
        Set-ItemProperty "Registry::HKEY_CLASSES_ROOT\batfile\shell\Open with\command" -Name "(Default)" -Value "{09799AFB-AD67-11d1-ABCD-00C04FC30936}" -Force
        Set-ItemProperty "Registry::HKEY_CLASSES_ROOT\batfile\shell\Open with\command" -Name "(Default)" -Value "{09799AFB-AD67-11d1-ABCD-00C04FC30936}" -Force

    }

    if ('TakeOwnership' -in $Entries){
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
$global:SendTo = [System.Environment]::GetFolderPath('SendTo')
function Get {
    [alias('g')] # minimalism at it's finest
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [Array]$Apps,
        [Switch]$DryRun
    )

    $FailedToInstall = $null # Reset that variable for later
    if ($Apps.Count -eq 1 -and (($Apps[0] -Split '\r?\n') -gt 1)){
        $Apps = $Apps[0] -Split '\r?\n'
    }
    if ($DryRun){
        ForEach($App in $Apps){
            "Installing $app."
        }
        return
    }

    ForEach($App in $Apps){ # Scoop exits when it throws

        switch ($App){
            'nvddl'{Get-ScoopApp utils/nvddl}
            {$_ -in 'Remux','Remuxer'}{
                Invoke-RestMethod https://github.com/couleurm/couleurstoolbox/raw/main/7%20FFmpeg/Old%20Toolbox%20scripts/Remux.bat -Verbose |
                Out-File "$SendTo\Remux.bat"

            }
            {$_ -in 'RemuxAVI','AVIRemuxer'}{
                Invoke-RestMethod https://github.com/couleurm/couleurstoolbox/raw/main/7%20FFmpeg/Old%20Toolbox%20scripts/Remux.bat -Verbose |
                Out-File "$SendTo\Remux - AVI.bat"
                $Content = (Get-Content "$SendTo\Remux - AVI.bat") -replace 'set container=mp4','set container=avi'
                Set-Content "$SendTo\Remux - AVI.bat" $Content
            }
            {$_ -in 'Voukoder','vk'}{Install-Voukoder}
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
            {$_ -in 'wt','windowsterminal','windows-terminal'}{Get-ScoopApp extras/windows-terminal}
            {$_ -in 'np++','Notepad++','notepadplusplus'}{Get-ScoopApp extras/notepadplusplus}
            {$_ -in 'DDU','DisplayDriverUninstaller'}{Get-ScoopApp extras/ddu}
            {$_ -in 'Afterburner','MSIAfterburner'}{Get-ScoopApp utils/msiafterburner}
            {$_ -in 'Everything','Everything-Alpha','Everything-Beta'}{Get-ScoopApp extras/everything-alpha}
            {$_ -In '7-Zip','7z','7Zip'}{Get-ScoopApp 7zip}
            {$_ -In 'Smoothie','sm'}{Install-FFmpeg;Get-ScoopApp utils/Smoothie}
            {$_ -In 'OBS','OBSstudio','OBS-Studio'}{Get-ScoopApp extras/obs-studio}
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
	Scraps the latest version of Sophia edition weither you have W10/11/LTSC/PS7,
	changes all function scopes to global and invokes it, as if it were importing it as a module

	You can find farag's dobonhonkerosly big Sophia Script at https://github.com/farag2/Sophia-Script-for-Windows
	And if you'd like using it as a GUI, try out SophiApp:  https://github.com/Sophia-Community/SophiApp
	
	Using the -Write parameter returns the script instead of piping it to Invoke-Expression
	.EXAMPLE
	Import-Sophia
	# Or for short:
	ipso
#>
function Import-Sophia {
	[alias('ipso')]
	param(
		[switch]
        $Write,

		[string]
        [ValidateSet(
            'de-DE',
            'en-US',
            'es-ES',
            'fr-FR',
            'hu-HU',
            'it-IT',
            'pt-BR',
            'ru-RU',
            'tr-TR',
            'uk-UA',
            'zh-CN'
        )]
        $OverrideLang
	)

	$SophiaVer = "Sophia Script for " # Gets appended with the correct win/ps version in the very next switch statement

switch ((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber){

	17763 {$SophiaVer += "Windows_10_LTSC_2019"}
	
	{($_ -ge 19041) -and ($_ -le 19044)}{

		if ($PSVersionTable.PSVersion.Major -eq 5){

			# Check if Windows 10 is an LTSC 2021
			if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName) -eq "Windows 10 Enterprise LTSC 2021"){

				$SophiaVer += "Windows_10_LTSC_2021"
			}else{

				$SophiaVer += "Windows_10"
			}
		}else{

			Write-Warning "PowerShell 7 core has not been tested as thoroughly, give Windows PowerShell a try if you're having issues"
			$SophiaVer += "Windows_10_PowerShell_7"
		}

	}
	22000 {

		if ($PSVersionTable.PSVersion.Major -eq 5){

			$SophiaVer += "Windows_11"
		}else{

			Write-Warning "PowerShell 7 core has not been tested as thoroughly, give Windows PowerShell a try if you're having issues"
			$SophiaVer +="Windows_11_PowerShell_7"
		}
	}
}



	$SupportedLanguages = @(
		'de-DE',
		'en-US',
		'es-ES',
		'fr-FR',
		'hu-HU',
		'it-IT',
		'pt-BR',
		'ru-RU',
		'tr-TR',
		'uk-UA',
		'zh-CN'
	)

	if($OverrideLang){
		if ($OverrideLang -NotIn $SupportedLanguages){
			Write-Warning "Language $OverrideLang may not be supported."
		}
		$Lang = $OverrideLang
	}
	elseif((Get-UICulture).Name -in $SupportedLanguages){
		$Lang = (Get-UICulture).Name
	}
	elseif((Get-UICulture).Name -eq "en-GB"){
		$Lang = 'en-US'
	}
	else{
		$Lang = 'en-US'
	}

	$Lang = (Get-UICulture).Name
	if ($OverrideLang){$Lang = $OverrideLang}

	if ($Lang -NotIn $SupportedLanguages){
		$Lang = 'en-US'
	}
	Try{
		$Hashtable = Invoke-RestMethod "https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/master/src/$($SophiaVer -Replace ' ','_')/Localizations/$Lang/Sophia.psd1" -ErrorAction Stop
	} Catch {
		Write-Warning "Failed to get Localizations with lang $Lang"
		return
	}
	While ($Hashtable[0] -ne 'C'){
		$Hashtable = $Hashtable.Substring(1) # BOM ((
	}
	$global:Localizations = $global:Localization = Invoke-Expression $HashTable

	Write-Verbose "Getting $SophiaVer"

	$RawURL = "https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/master/src/$($SophiaVer -Replace ' ','_')/Module/Sophia.psm1"
	Write-Verbose $RawURL

	$SophiaFunctions = (Invoke-RestMethod $RawURL -ErrorAction Stop)

	While ($SophiaFunctions[0] -ne '<'){
		$SophiaFunctions = $SophiaFunctions.Substring(1) # BOM ((
	}

	if ($Write){
		return $SophiaFunctions
	}else{
		New-Module -Name "Sophia Script (TL)" -ScriptBlock ([ScriptBlock]::Create($SophiaFunctions)) | Import-Module
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
function Launch{
	[alias('l')]
	param(
		[ValidateSet(
			'DisplayDriverUninstaller',
			'NVCleanstall',
			'NvidiaProfileInspector',
			'MSIUtilityV3',
			'Rufus',
			'AutoRuns',
			'Procmon',
			'CustomResolutionUtility',
			'NotepadReplacer',
			'privacy.sexy'
			#! TODO: NVProfileInspector, MSIUtility, CRU, Notepadreplacer, BulkCrapUninstaller, https://www.bill2-software.com/processmanager/exe/BPM-Setup.exe
		)]
		[Array]$Apps,
		[Switch]$DontLaunch, # Just keep them tidy in the Downloads folder))
		# This is the non hardcoded Downloads folder path s/o @farag2
		[String]$OutDir = (Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}")
	)

	Add-Type -AssemblyName System.IO.Compression.FileSystem

	function Invoke-Download{
		param(
			[String]$URL, # Parses mediafire
			[String]$AppName,
			[Switch]$Scoop, # Scoop 'bucket/manifest' name
			[String]$PathToBinary, # In the zip
			[String]$Checksum,
			[String]$SelfExtracting7z # e.g for DDU
		)

		if (-Not(Test-Path $env:TMP)){
			throw "TMP environment variable not found [$env:TMP]"
		}

		if($Scoop){
			$Bucket, $Manifest = $URL -split '/'

			$Repos = @{

				main = @{org = 'ScoopInstaller';repo = 'main';branch = 'master'}
				extras = @{org = 'ScoopInstaller';repo = 'extras';branch = 'master'}
				utils = @{org = 'couleur-tweak-tips';repo = 'utils';branch = 'main'}
				nirsoft = @{org = 'kodybrown';repo = 'scoop-nirsoft';branch = 'master'}
				games = @{org = 'ScoopInstaller';repo = 'games';branch = 'master'}
				'nerd-fonts' = @{org = 'ScoopInstaller';repo = 'nerd-fonts';branch = 'master'}
				versions = @{org = 'ScoopInstaller';repo = 'versions';branch = 'master'}
				java = @{org = 'ScoopInstaller';repo = 'java';branch = 'master'}
			}
			$repo = $Repos.$Bucket
			$URL = "https://raw.githubusercontent.com/$($repo.org)/$($repo.repo)/$($repo.branch)/bucket/$Manifest.json"
			$URL, $Version = Invoke-RestMethod $URL | ForEach-Object {$PSItem.URL, $PSItem.Version}
		}elseif($URL -Like "*mediafire.com*"){
			$URL = (Invoke-WebRequest -UseBasicParsing $URL).Links.href | Where-Object {$PSItem -Like "http*://download*.mediafire.com/*"}
		}

		if ($AppName){
			$FileName = $AppName
		}else{
			$FileName = $Manifest
		}
		
		if ($Version){$FileName += " $Version"}

		$Extension = [io.path]::GetExtension((($URL -replace '#/dl.7z') | Split-Path -Leaf))

		$OutFile = "$env:TMP\$FileName$Extension"
		if (-Not(Test-Path $OutFile)){
			curl.exe -#L -A "Scoop" $URL -o"$OutFile"
		}

		if($Checksum){
			$Parameters = @{
				Path = $OutFile
			}
			if ($Checksum -Like "*:*"){ # Contains a :
				$Algo, $Checksum = $Checksum -Split ':' # To split hash and algo, eg md5:8424509737CEDBDE4BA9E9A780D5CE96
				$Parameters += @{
					Algorithm = $Algo 
				}
			}
			if ($Checksum -ne (Get-FileHash @Parameters).Hash){
				throw "Hash provided $Checksum does not match $OutFile"
			}
		}

		if ($Extension -eq '.zip'){
			$OutDir = "$env:TMP\$FileName\"
			if (-Not(Test-Path $OutDir)){
				[System.IO.Compression.ZipFile]::ExtractToDirectory($OutFile, $OutDir)
			}

			if ($PathToBinary){
				$OutDir = Join-Path $OutDir $PathToBinary
			}
			$OutFile = $OutDir # To not have to check for the following statement twice
		}elseif($SelfExtracting7z){
			Start-Process -FilePath $OutFile -ArgumentList "-y" -Wait
			$SelfExtracting7z = $SelfExtracting7z -replace "%VER%", $Version
			if (-Not(Test-Path "$env:TMP\$SelfExtracting7z" -PathType Container)){
				throw "Self extracting 7-Zip got wrong path: $SelfExtracting7z"
			}
			$OutDir = $SelfExtracting7z
		}

		if (-Not(Test-Path $OutFile)){
			throw "$OutFile could not be found"
		}

		return $OutFile

	}

	$Paths = @()

	$Apps | ForEach-Object { # Cycles through given apps
		Write-Host "getting $PSItem"
		$Paths += switch ($PSItem){
			DisplayDriverUninstaller{ Invoke-Download -URL extras/ddu -Scoop -PathToBinary "Display Driver Uninstaller.exe" -SelfExtracting7z "DDU v%VER%" -AppName DDU }
			NVCleanstall{ Invoke-Download -URL extras/nvcleanstall -Scoop -AppName NVCleanstall -PathToBinary "NVCleanstall.exe" }
			NvidiaProfileInspector{ Invoke-Download -URL extras/nvidia-profile-inspector -Scoop -AppName NvidiaProfileInspector -PathToBinary 'nvidiaProfileInspector.exe' }
			MSIUtilityV3{
				Write-Warning "MSI mode is already applied by default on NVIDIA 1600/2000/3000 GPUs and AMD cards"
				Invoke-Download -URL https://www.mediafire.com/file/ewpy1p0rr132thk/MSI_util_v3.zip/file -AppName "MSIUtilV3" -PathToBinary "MSI_util_v3.exe" -Checksum "md5:8424509737CEDBDE4BA9E9A780D5CE96"
			}
			Rufus{ Invoke-Download -URL extras/rufus -Scoop -AppName rufus}
			AutoRuns{ Invoke-Download -URL https://download.sysinternals.com/files/Autoruns.zip -AppName AutoRuns -PathToBinary Autoruns64.exe }
			Procmon{ Invoke-Download -URL https://download.sysinternals.com/files/ProcessMonitor.zip -AppName Procmon -PathToBinary Procmon64.exe }
			CustomResolutionUtility { Invoke-Download -URL extras/cru -Scoop -AppName CRU -PathToBinary CRU.exe}
			NotepadReplacer { Invoke-Download -URL utils/notepadreplacer -Scoop -AppName NotepadReplacer}
			privacy.sexy { Invoke-Download -URL utils/privacysexy -Scoop -AppName privacysexy}
		}
	}
	return $Paths
}
<#!TODO:
    Scan windows defender
    Git Bash
    Rotate pictures
    Open with code
    Open with visual studio
    Add to favorites
#>

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
            'SendTo',
            'DrivesInSendTo',
            'VLC'
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

    if ('DrivesInSendTo' -in $Entries){
        Set-ItemProperty "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoDrivesInSendToMenu -Value 1
    }
    
    if ('OpenWithOnBatchFiles' -in $Entries){
        foreach ($Ext in 'bat','cmd'){
            Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\$($Ext)file\shell\Open with\command" -Force -Recurse
        }
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

    if ('VLC' -in $Entries){

        @(
            'Directory\shell\PlayWithVLC'
            'Directory\shell\AddtoPlaylistVLC'
            
        ) | ForEach-Object {
            if (Test-Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\$_"){
                Remove-Item -LiteralPath "Registry::HKEY_CLASSES_ROOT\Directory\shell\$PSItem" -Recurse -Force
            }
        }
        ForEach($Context in ('PlayWithVLC','AddtoPlaylistVLC')){
            @(
                '3g2', '3ga', '3gp', '3gp2', '3gpp', '669', 'a52', 'aac', 'ac3', 'adt', 'adts', 'aif', 'aifc', 'aiff',
                'amr', 'amv', 'aob', 'ape', 'asf', 'asx', 'au', 'avi', 'b4s', 'bik', 'Bluray', 'caf', 'cda', 'CDAudio',
                'cue', 'dav', 'divx', 'drc', 'dts', 'dv', 'DVDMovie', 'dvr-ms', 'evo', 'f4v', 'flac', 'flv', 'gvi', 'gxf',
                'ifo', 'iso', 'it', 'm1v', 'm2t', 'm2ts', 'm2v', 'm3u', 'm3u8', 'm4a', 'm4p', 'm4v', 'mid', 'mka', 'mkv',
                'mlp', 'mod', 'mov', 'mp1', 'mp2', 'mp2v', 'mp3', 'mp4', 'mp4v', 'mpa', 'mpc', 'mpe', 'mpeg', 'mpeg1',
                'mpeg2', 'mpeg4', 'mpg', 'mpga', 'mpv2', 'mts', 'mtv', 'mxf', 'nsv', 'nuv', 'oga', 'ogg', 'ogm', 'ogv',
                'ogx', 'oma', 'OPENFolder', 'opus', 'pls', 'qcp', 'ra', 'ram', 'rar', 'rec', 'rm', 'rmi', 'rmvb', 'rpl',
                's3m', 'sdp', 'snd', 'spx', 'SVCDMovie', 'thp', 'tod', 'tp', 'ts', 'tta', 'tts', 'VCDMovie', 'vlc', 'vlt',
                'vob', 'voc', 'vqf', 'vro', 'w64', 'wav', 'webm', 'wma', 'wmv', 'wpl', 'wsz', 'wtv', 'wv', 'wvx', 'xa', 'xesc',
                'xm', 'xspf', 'zip', 'zpl','3g2','3ga','3gp','3gp2','3gpp'

            ) | ForEach-Object {
                $Key = "Registry::HKEY_CLASSES_ROOT\VLC.$PSItem\shell\$Context"
                if (Test-Path $Key){
                    Remove-Item -LiteralPath $Key -Recurse -Force
                }
            }
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
