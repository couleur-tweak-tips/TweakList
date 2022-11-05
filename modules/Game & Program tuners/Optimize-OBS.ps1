function Optimize-OBS {
    <#
    .SYNOPSIS
    Display Name: Optimize OBS
    Platform: Linux; Windows
    Category: Optimizations

    .DESCRIPTION
    Tune your OBS for a specific usecase in the snap of a finger!

    .PARAMETER Encoder
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