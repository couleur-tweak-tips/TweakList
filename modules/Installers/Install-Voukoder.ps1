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
