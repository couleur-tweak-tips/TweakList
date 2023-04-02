function Set-SteamLaunchOptions {
   param(
        [Parameter(Mandatory=$True)]
        [int]$GameID,

        [String]$SteamPath = (Get-SteamPath),

        [Parameter(Mandatory=$True)]
        [String]$Options
    )
    
    if (!$SteamPath){
        Write-Host "Set-LaunchOptions: Steam's path could not be found, returning."
        return
    }

    $Users = @{}

    Get-ChildItem $SteamPath/userdata -Directory | ForEach-Object {
        
        $localconfig = Get-Item "$PSItem/config/localconfig.vdf" -ErrorAction Stop
        $configobject = ConvertFrom-VDF (Get-Content $localconfig)
        $PersonaName = $configobject.UserLocalConfigStore.friends.PersonaName

        $Users += @{
            $PersonaName = $localconfig
        }

    }

    $localconfig = if ($Users.Count -gt 1){
        $Selected = (Invoke-CheckBox -Title "Select users to apply launch options on" -Items ([Array]$Users.Keys))
        if (!$Selected){
            Write-Host "No user selected, returning."
            returned
        }
        $Users[$Selected]
    }elseif($Users.Count -eq 1){
        Write-Host "Configuring launch options on Steam user ``$($Users.Keys)``" -ForegroundColor Green
        $localconfig # the loop has only went through a single user
    }else{
        Write-Host "No accounts found in $SteamPath\userdata to configure, returning."
        return
    }

    if(Get-Process steam -ErrorAction Ignore){
        
        Write-Warning "Steam is still running, launch options may get overwrote"
        
    }

    Copy-Item -Path $localconfig -Destination "$($localconfig.FullName).bak"
    Write-Host "localconfig.vdf backed up @ $($localconfig.FullName).bak)"

    $Base = ConvertFrom-VDF (Get-Content $localconfig -ErrorAction Stop | Where-Object {$_}) -ErrorAction Stop

    if (!$base.UserLocalConfigStore.Software.Valve.Steam.apps.$GameID){
        Write-Host "Set-LaunchOptions: No local config for game ID ```$GameID``"
        return
    }

    $base.UserLocalConfigStore.Software.Valve.Steam.apps.$GameID.LaunchOptions = $Options

    ConvertTo-VDF $Base | Set-Content $localconfig -ErrorAction Stop


    
}