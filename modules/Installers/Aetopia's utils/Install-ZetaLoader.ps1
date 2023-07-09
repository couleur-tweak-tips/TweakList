function Install-ZetaLoader {
    $GameInstallDir = Get-SteamGameInstallDir "Halo Infinite"
    $ZetaLoader = "$((Invoke-RestMethod "https://api.github.com/repos/Aetopia/ZetaLoader/releases/latest").assets[0].browser_download_url)"
    if (!$GameInstallDir) {
        Write-Error "Halo Infinite hasn't been installed via Steam."
        exit 1
    }
    Write-Output "Installing ZetaLoader..."
    Invoke-RestMethod -Uri "$ZetaLoader" -OutFile "$ENV:TEMP\dpapi.dll"
    @("$GameInstallDir\game\dpapi.dll", "$GameInstallDir\subgames\CampaignS1\dpapi.dll") | ForEach-Object { Copy-Item -Path "$ENV:TEMP\dpapi.dll" -Destination $_ -ErrorAction SilentlyContinue}
    Write-Output "ZetaLoader has been installed."
}
