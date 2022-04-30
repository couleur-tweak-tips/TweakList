function Optimize-OBS {
    [alias('optobs')]
    param(
        [Parameter(Mandatory)] # Override encoder check
        [ValidateSet('x264','NVENC','AMF'<#,'QuickSync'#>)]
        [String]$Encoder,
        
        [ValidateScript({Test-Path -Path $_ -Type Directory})]
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

    # Applies to all patches
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

    ipmo "D:\GitHub\ps-menu.psm1"
    ipmo "D:\GitHub\TweakScript\helpers\PsInI\Get-IniContent.ps1"
    ipmo "D:\GitHub\TweakScript\helpers\Get-ShortcutTarget.ps1"
    ipmo "D:\GitHub\TweakScript\helpers\Merge-Hashtables.ps1"
    ipmo "D:\GitHub\TweakScript\modules\Set-CompatibilitySettings.ps1"

    if (-Not($OBS64Path)){
        
        $StartMenu = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu" -Recurse -Include 'OBS Studio*.lnk'
        if ($StartMenu.Count -gt 1){

            $Shortcuts = $null 
            ForEach($Lnk in $StartMenu){$Shortcuts += @{$Lnk.BaseName = $Lnk.FullName}}
            "There are multiple OBS shortcuts in your Start Menu folder. Please select one."
            $ShortcutName = menu ($Shortcuts.Keys -Split [System.Environment]::NewLine)
            $StartMenu = $Shortcuts.$ShortcutName
        }

        $OBS64Path = Get-ShortcutTarget $StartMenu
    }

    Set-CompatibilitySettings $OBS64Path -RunAsAdmin

    if (Test-Path (Resolve-Path "$OBS64Path\..\..\..\portable_mode.txt")){ # "Portable Mode" makes OBS make the config in it's own folder, else it's in appdata

        $ProfilesDir = (Resolve-Path "$OBS64Path\..\..\..\config\obs-studio\basic\profiles" -ErrorAction Stop)
    }else{
        $ProfilesDir = (Resolve-Path "$env:APPDATA\obs-studio\config\obs-studio\basic\profiles" -ErrorAction Stop)
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