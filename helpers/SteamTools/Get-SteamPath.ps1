function Get-SteamPath {
    # Get the Steam installation directory.

    $MUICache = "Registry::HKCR\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    $Protocol = "Registry::HKCR\steam\Shell\Open\Command"
    $Steam = Get-ItemPropertyValue "Registry::HKCU\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue
    
    # MUICache
    if (!$Steam) {
        $Steam = Split-Path (((Get-Item "$MUICache").Property | Where-Object { $PSItem -Like "*Steam*" } |
                Where-Object { (Get-ItemPropertyValue "$MUICache" -Name $PSItem) -eq "Steam" }).TrimEnd(".FriendlyAppName"))
    }

    # Steam Browser Protocol
    if (!$Steam) {
        $Steam = Split-Path (((Get-ItemPropertyValue "$Protocol" -Name "(Default)" -ErrorAction SilentlyContinue) -Split "--", 2, "SimpleMatch")[0]).Trim('"')
    }

    return $Steam.ToLower()
}