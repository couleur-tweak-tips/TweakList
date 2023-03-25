# Source: https://github.com/Aetopia/Install-NVCPL
function Install-NVCPL {
  if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

      choice.exe /C 12 /N /M "Install NVIDIA Control Panel as:`n1. Win32 App`n2. UWP App`n>"

      $NVCPL = "$ENV:TEMP\NVCPL.zip"
      $InstallationDirectory = "$ENV:PROGRAMFILES\NVIDIA Corporation\Control Panel Client"
      $ShortcutFile = "$ENV:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\NVIDIA Control Panel.lnk"
      if ($LASTEXITCODE -eq 2) { $NVCPL = "$NVCPL.appx" }
      if ($null -eq (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "NVIDIA*" })) { Write-Error "No NVIDIA GPU found." -ErrorAction Stop }

      # Disable Telemetry.
      New-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" -Name "OptInOrOutPreference" -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
      New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup" -Name "SendTelemetryData" -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
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

      if ($LASTEXITCODE -eq 2) {
          Write-Output "Installing the NVIDIA Control Panel as an UWP app..."
          Add-AppxPackage "$NVCPL" -ForceApplicationShutdown -ForceUpdateFromAnyVersion
      }
      else {

          Write-Output "Installing the NVIDIA Control Panel as a Win32 app..."

          # Run the NVIDIA Control Panel as an Administrator.
          New-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -ErrorAction SilentlyContinue | Out-Null
          New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$InstallationDirectory\nvcplui.exe" -Value "~ RUNASADMIN" -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null

          # Disable the NVIDIA Root Container Service. The service runs when the NVIDIA Control Panel is launched.
          Stop-Process -Name "NVDisplay.Container" -Force -ErrorAction SilentlyContinue
          Set-Service "NVDisplay.ContainerLocalSystem" -StartupType Disabled -ErrorAction SilentlyContinue
          Stop-Service "NVDisplay.ContainerLocalSystem" -Force -ErrorAction SilentlyContinue
          foreach ($File in ($InstallationDirectory, $ShortcutFile)) { Remove-Item "$File" -Recurse -Force -ErrorAction SilentlyContinue }
          Expand-Archive "$NVCPL" "$InstallationDirectory" -Force

          # This DLL is needed inorder to suppress the annoying pop-up that says the UWP Control Panel isn't installed.
          Invoke-RestMethod "$((Invoke-RestMethod "https://api.github.com/repos/Aetopia/Install-NVCPL/releases/latest").assets.browser_download_url)" -OutFile "$InstallationDirectory\nvcpluir.dll"
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
