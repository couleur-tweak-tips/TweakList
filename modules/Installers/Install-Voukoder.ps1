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



        {$_.Path.StartsWith('vegas')}{

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
