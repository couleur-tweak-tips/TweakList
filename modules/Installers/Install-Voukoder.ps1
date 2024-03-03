function Install-Voukoder {
    [CmdletBinding()]
    [alias('isvk')]
    param(
        [Switch]$GetTemplates
            # Skip Voukoder installation and just get to the template selector
    )

    function Get-VoukoderProgram ($Name){
        # Parses the registry manually instead of using PackageManagement's Get-Package

        $Programs = @(
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

        ) | Where-Object {Test-path $_} |

        Get-ItemProperty |  Where-Object Publisher -eq 'Daniel Stankewitz' |
                Select-Object -Property @{n='Name';     e='DisplayName'   },
                                        @{n='Version';  e='DisplayVersion'},
                                        @{n='UninstallString'; e='UninstallString'}
        
        return $Programs | Where-Object Name -Like $Name
    }

    if (!$GetTemplates){
    
        $LatestCore = (Invoke-RestMethod https://api.github.com/repos/Vouk/voukoder/releases/latest)[0]
            # get the latest release manifest from GitHub's API

        if (($tag = $LatestCore.tag_name) -NotLike "*.*"){
            $tag += ".0" # E.g "12" will not convert to a version type, "12.0" will
        }
        [Version]$LatestCoreVersion = $tag

        $Core = Get-VoukoderProgram -Name "Voukoder*" -ErrorAction Ignore | # Find all programs starting with Voukoder
            Where-Object Name -NotLike "*Connector*" | Where-Object Name -NotLike "*Pro*" # Exclude connectors and Voukoder Pro

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

            $Path = $Tree.path | Where-Object {$_ -Like "$Pattern*$LCV*.*"} # get the absolute path with the latest version
            $Connectors += @{$NLE = "https://github.com/Vouk/voukoder-connectors/raw/master/$Path"}
            Remove-Variable -Name NLE
        }

        $Processes = @(
            'vegas*'
            'Adobe Premiere Pro'
            'AfterFX'
            'Resolve'
        )

        $Found = { Get-Process $Processes -ErrorAction Ignore }

        if (-not (. $Found)){ # If $Found scriptblock returns nothing
            Write-Host "[!] Open your video editor" -ForegroundColor Red
            Write-Host "Voukoder supports: VEGAS 12-20, Premiere, After Effects, DaVinci Resolve (ONLY PAID `"Studio `"VERSION)" -ForeGroundColor Green
            Write-Host "Looking for processes: $($Processes -join ', ')" -ForegroundColor DarkGray
            While(-not (. $Found)){
                Start-Sleep -Seconds 1
            }
        }
        Write-Host @(
            "`nDetected the following video editor(s):`n`n"
            $(. $Found | Select-Object MainWindowTitle, Path, FileVersion | Out-String)
            )

        function Get-Connector ($PackageName, $Key, $NLEDir, $InnoFlag){
            # Key is to get the right connector URL in $Connector hashtable
            
            function Install-Connector {
                $msiPath = "$env:TMP\Voukoder Connector-$Key.msi"
                curl.exe -# -L $Connectors.$Key -o"$msiPath"
                Write-Verbose "Installing $msiPath at $InnoFlag=$NLEDir" -Verbose
                cmd /c "msiexec /i `"$msiPath`" /qb $InnoFlag=`"$NLEDir`" /log `"$env:TEMP\Voukoder $InnoFlag.txt`""
                # msiexec /i "$msiPath" /qb "$InnoFlag=`"$NLEDir`""
                if ($LASTEXITCODE){
                    Installer returned with error code $LASTEXITCODE
                }
            }

            $CurrentConnector = (Get-VoukoderProgram -Name $PackageName)
            if ($CurrentConnector){
                [Version]$CurrentConnectorVersion = $CurrentConnector.Version
                [Version]$LatestConnector = $Connectors.$Key | ConnectorVer # Parse connector version
                if ($LatestConnector -gt $CurrentConnectorVersion){

                    Write-Host "Upgrading $PackageName from $CurrentConnectorVersion to $LatestConnector"
                    Start-Process -FilePath msiexec -ArgumentList "/qb /x {$($CurrentConnector.TagId)}" -Wait -NoNewWindow
                    Install-Connector
                }
            } else {

                Install-Connector
            }
        }
        $NLEs = Get-Process $Processes -ErrorAction Ignore
        ForEach($NLE in $NLEs){

            switch ($NLE){

                {(Split-Path $_.Path -Leaf) -in 'vegas180.exe', 'vegas190.exe','vegas200.exe'} {
                    Write-Verbose "Using newer VEGAS"

                    $VegVer = (Split-Path $_.Path -Leaf) -replace 'vegas' -replace '0\.exe'

                    Get-Connector -PackageName "Voukoder connector for VEGAS Pro $VegVer" -Key "vegas$VegVer" -NLEDir (Split-Path $_.Path -Parent) -InnoFlag VEGASDIR
                    
                    continue # Needs to loop over the next switch, which would've matched and also thought it needed to install an older Version
                }


                {(Split-Path $_.Path -Leaf) -Like 'vegas*.exe'}{
                    Write-Host "/!\ Old-VEGAS connector installation may fail if you already have a connector for newer VEGAS versions" -ForegroundColor Red
                    Get-Connector -PackageName "Voukoder connector for VEGAS" -Key vegas -NLEDir (Split-Path $_.Path -Parent) -InnoFlag VEGASDIR
                }


                {(Split-Path $_.Path -Leaf) -eq 'afterfx.exe'} {
                    Get-Connector -PackageName 'Voukoder Connector for Adobe After Effects' -Key aftereffects -NLEDir "$env:ProgramFiles\Adobe\Common\Plug-ins\7.0\MediaCore" -InnoFlag INSTALLDIR
                }


                {(Split-Path $_.Path -Leaf) -eq 'Adobe Premiere Pro.exe'}{
                    Get-Connector -PackageName 'Voukoder connector for Premiere' -Key premiere -NLEDir "$env:ProgramFiles\Adobe\Common\Plug-ins\7.0\MediaCore" -InnoFlag TGDir
                }


                {(Split-Path $_.Path -Leaf) -eq 'Resolve.exe'}{
                    Write-Warning "Voukoder's connector for Resolve is ONLY FOR IT'S PAID `"Studio`" VERSION"
                    pause
                    
                    $IOPlugins = "$env:ProgramData\Blackmagic Design\DaVinci Resolve\Support\IOPlugins"
                    $dvcpBundle = "$IOPlugins\voukoder_plugin.dvcp.bundle"

                    if (-Not(Test-Path $IOPlugins)){
                        New-Item -ItemType Directory -Path $IOPlugins | Out-Null
                    }
                    elseif (Test-Path $dvcpBundle -PathType Container){
                        if (-Not(Get-Boolean "Would you like to reinstall/update the Voukoder Resolve plugin? (Y/N)")){continue}
                        Remove-Item $dvcpBundle -Force -Recurse
                    }

                    $Zip = "$env:TMP\Voukoder-Connector-Resolve.zip"
                    curl.exe -# -L $Connectors.Resolve -o"$Zip"

                    $ExtractDir = "$env:TMP\Voukoder-Connector-Resolve"
                    Remove-Item $ExtractDir -Recurse -Force -ErrorAction Ignore
                    Expand-Archive $Zip -Destination $ExtractDir

                    Copy-Item "$ExtractDir\voukoder_plugin.dvcp.bundle" $IOPlugins -Recurse
                    
                    Write-Warning "If connection failed you should find instructions in $ExtractDir\README.txt"
                }
            }
        }
        $NLEBin = $NLE.Path
    }else{
        $AvailableNLETemplates = @{
            "Vegas Pro" = "vegas200.exe"
            "Premiere Pro" = "Adobe Premiere Pro.exe"
            "After Effects" = "AfterFX.exe"
        }
        $NLE = Menu -menuItems $AvailableNLETemplates.Keys
        $NLEBin = $AvailableNLETemplates.$NLE
    }

        # Converts 
        # https://cdn.discordapp.com/attachments/969870701798522901/972541638578667540/HEVC_NVENC_Upscale.sft2
        # To hashtable with key "HEVC NVENC + Upscale" and val the URL

    filter File2Display {
        [IO.Path]::GetFileNameWithoutExtension($_) -replace '_',' ' -replace " Upscale", " + Upscale" -replace '  ',' '
    }

    $VegasTemplates = @(

        'https://github.com/couleur-tweak-tips/TweakList/releases/download/vegas-voukoder-presets/HEVC_NVENC_Upscale.sft2'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/vegas-voukoder-presets/HEVC_NVENC.sft2'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/vegas-voukoder-presets/HEVC_NVENC__Upscale.sft2'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/vegas-voukoder-presets/H264_NVENC.sft2'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/vegas-voukoder-presets/x265_Upscale.sft2'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/vegas-voukoder-presets/x265.sft2'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/vegas-voukoder-presets/x264_Upscale.sft2'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/vegas-voukoder-presets/x264.sft2'

        ) | ForEach-Object {
        [Ordered]@{($_ | File2Display) = $_}
    }

    $PremiereTemplates = @(
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/premiere-voukoder-presets/HEVC_NVENC__Upscale.epr'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/premiere-voukoder-presets/HEVC_NVENC.epr'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/premiere-voukoder-presets/H264_NVENC__Upscale.epr'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/premiere-voukoder-presets/H264_NVENC.epr'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/premiere-voukoder-presets/x264__Upscale.epr'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/premiere-voukoder-presets/x264.epr'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/premiere-voukoder-presets/x265__Upscale.epr'
        'https://github.com/couleur-tweak-tips/TweakList/releases/download/premiere-voukoder-presets/x265.epr'
    ) | ForEach-Object {
        [Ordered]@{($_ | File2Display) = $_}
    }

    switch($NLEBin){

        {($NLEBin | Split-Path -Leaf).StartsWith('vegas')}{

            $NLETerm = "Vegas"
            $TemplatesFolder = "$env:APPDATA\VEGAS\Render Templates\voukoder"

            if (-Not(Test-Path $TemplatesFolder)){
                New-Item -ItemType Directory -Path $TemplatesFolder -Force | Out-Null
            }

            $SelectedTemplates =  Invoke-Checkbox -Items $VegasTemplates.Keys -Title "Select VEGAS render templates to install"

            ForEach ($Template in $SelectedTemplates){
                if (Test-Path ($TPPath = "$TemplatesFolder\$Template.sft2")){
                    Remove-Item $TPPath -Force
                }
                curl.exe -# -sSL $VegasTemplates.$Template -o"$TPPath"
            }
        }



        {($NLEBin | Split-Path -Leaf).StartsWith('Adobe Premiere Pro.exe')}{
            
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




        {($NLEBin | Split-Path -Leaf).StartsWith('AfterFX.exe')}{
            $NLETerm = 'After Effects'

            "Opening a tutorial in your browser and downloading the AE templates file.."
            Start-Sleep -Seconds 2
            if (-Not(Test-Path ($TPDir = "$env:TMP\AE_Templates"))){
                New-Item -ItemType Directory -Path $TPDir -Force | Out-Null
            }
            curl.exe -# -sSL https://github.com/couleur-tweak-tips/TweakList/releases/download/after-effects-voukoder-presets/CTT_AE_VOUKODER_TEMPLATES.aom -o"$TPDir\CTT_AE_VOUKODER_TEMPLATES.aom"

            Start-Process -FilePath explorer.exe -ArgumentList "/select,`"$TPDir\CTT_AE_VOUKODER_TEMPLATES.aom`""
            $Tutorial = 'https://i.imgur.com/XCaJGoV.mp4'
            try {
                Start-Process $Tutorial
            } catch { # If the user does not have any browser
                "Tutorial URL: $Tutorial" 
            }
        }



        default{
            Write-Host "Your video editor ($($NLEBin)) does not have any pre-made templates for me to propose you" -ForegroundColor Red
            $NLETerm = "your video editor"
        }
    }
    Write-Host "Installation script finished, follow instructions (if any)"
    Write-Host "Then restart $NLETerm to make sure Voukoder render templates have loaded." -ForegroundColor Red

}
