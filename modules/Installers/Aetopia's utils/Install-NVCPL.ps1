Function Install-NVCPL {
    if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

        choice.exe /C 1234 /N /M "NVIDIA Control Panel Installer:
1. Install as Win32 App (NVIDIA Display Container LS: Default)
2. Install as Win32 App (NVIDIA Display Container LS: Manual)
3. Install as UWP App
4. Uninstall
>"

        $NVCPL = "$ENV:TEMP\NVCPL.zip"
        $NVIDIACorporation = "HKCU:\Software\NVIDIA Corporation"
        $NVCPLConfigurationKeys = @("NVControlPanel2\Client", "Global\NvCplApi\Policies", "NvTray" )
        $InstallationDirectory = "$ENV:PROGRAMFILES\NVIDIA Corporation\Control Panel Client"
        $ShortcutFile = "$ENV:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\NVIDIA Control Panel.lnk"
        if ($LASTEXITCODE -eq 3) { $NVCPL = "$NVCPL.appx" }
        if ($null -eq (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "NVIDIA*" })) { Write-Error "No NVIDIA GPU found." -ErrorAction Stop }

        if ($LASTEXITCODE -eq 4) {
            Write-Output "Uninstalling the NVIDIA Control Panel..."
            Get-AppxPackage "NVIDIACorp.NVIDIAControlPanel" | Remove-AppxPackage
            Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$InstallationDirectory\nvcplui.exe" -ErrorAction SilentlyContinue
            @($InstallationDirectory, $ShortcutFile) | ForEach-Object { Remove-Item "$_" -Recurse -Force -ErrorAction SilentlyContinue }
            Write-Output "NVIDIA Control Panel Uninstalled!"
            return
        }
    
        # Setup NVIDIA Control Panel.
        Remove-Item "$NVIDIACorporation" -Force -Recurse -ErrorAction SilentlyContinue
        New-Item "$NVIDIACorporation" | Out-Null
        $NVCPLConfigurationKeys | 
        ForEach-Object { New-Item "$NVIDIACorporation\$_" -Force -ErrorAction SilentlyContinue | Out-Null }
        New-ItemProperty  "$NVIDIACorporation\$($NVCPLConfigurationKeys[0])" -Name "ShowSedoanEula" -Value 1 -PropertyType DWORD | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" -Name "OptInOrOutPreference" -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup" -Name "SendTelemetryData" -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak"  -Name "DisableStoreNvCplNotifications" -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
    
        # Using rg-adguard to fetch the latest version of the NVIDIA Control Panel.
        $Body = @{
            type = 'url'
            url  = "https://apps.microsoft.com/store/detail/nvidia-control-panel/9NF8H0H7WMLT"
            ring = 'RP'
            lang = 'en-US' 
        }
        Write-Output "Getting the latest version of the NVIDIA Control Panel from the Microsoft Store..."
        $Link = ((Invoke-RestMethod -Method Post -Uri "https://store.rg-adguard.net/api/GetFiles" -ContentType "application/x-www-form-urlencoded" -Body $Body) -Split "`n" | 
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -like ("*http://tlu.dl.delivery.mp.microsoft.com*") } |
            ForEach-Object { ((($_ -split "<td>", 2, "SimpleMatch")[1] -Split "rel=", 2, "SimpleMatch")[0] -Split "<a href=", 2, "SimpleMatch")[1].Trim().Trim('"') })[-1]
        Invoke-RestMethod "$Link" -OutFile "$NVCPL"

        if ($LASTEXITCODE -eq 3) {
            Write-Output "Installing the NVIDIA Control Panel as an UWP app..."
            Add-AppxPackage "$NVCPL" -ForceApplicationShutdown -ForceUpdateFromAnyVersion
        }
        else {

            Write-Output "Installing the NVIDIA Control Panel as a Win32 app..."
        
            # Configure the NVIDIA Control Panel.
            New-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -ErrorAction SilentlyContinue | Out-Null
            New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$InstallationDirectory\nvcplui.exe" -Value "~ RUNASADMIN" -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
            New-ItemProperty "$NVIDIACorporation\$($NVCPLConfigurationKeys[1])" -Name "ContextUIPolicy" -Value 0 -PropertyType DWORD | Out-Null
            New-ItemProperty  "$NVIDIACorporation\$($NVCPLConfigurationKeys[2])" -Name "StartOnLogin" -Value 0 -PropertyType DWORD | Out-Null
            @($InstallationDirectory, $ShortcutFile) | ForEach-Object { Remove-Item "$_" -Recurse -Force -ErrorAction SilentlyContinue }
            Expand-Archive "$NVCPL" "$InstallationDirectory" -Force
        
            if ($LASTEXITCODE -eq 2) {
                Write-Host "Configuring NVIDIA Display Container LS Service..."
                Stop-Process -Name "NVDisplay.Container" -Force -ErrorAction SilentlyContinue
                Set-Service "NVDisplay.ContainerLocalSystem" -StartupType Disabled -ErrorAction SilentlyContinue
                Stop-Service "NVDisplay.ContainerLocalSystem" -Force -ErrorAction SilentlyContinue
                # This DLL is needed inorder to run the NVIDIA Display Container LS on demand.
                Invoke-RestMethod "$((Invoke-RestMethod "https://api.github.com/repos/Aetopia/Install-NVCPL/releases/latest").assets.browser_download_url)" -OutFile "$InstallationDirectory\nvcpluir.dll"
            }

            $WSShell = New-Object -ComObject "WScript.Shell"
            $Shortcut = $WSShell.CreateShortcut("$ShortcutFile")
            $Shortcut.TargetPath = "$InstallationDirectory\nvcplui.exe"
            $Shortcut.IconLocation = "$InstallationDirectory\nvcplui.exe, 0"
            $Shortcut.Save()
        }
        Write-Output "NVIDIA Control Panel Installed!"
    }
    else {
        Write-Error "Run this script as an Administrator." -ErrorAction Stop
    }
}
