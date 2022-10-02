function Get-TLShell {
    param(
        [switch]$Offline,
        [switch]$DontOpen
        )
    
    $WR = "$env:LOCALAPPDATA\Microsoft\WindowsApps" # I've had the habit of calling this folder WR
                                                    # because it's the only folder I know that is added to path
                                                    # that you don't need perms to access.

if ($Offline){
    
    try {
        $Master = Invoke-RestMethod -UseBasicParsing https://raw.githubusercontent.com/couleur-tweak-tips/TweakList/master/Master.ps1
    } catch {
        Write-Host "Failed to get Master.ps1 from TweakList GitHub" -ForegroundColor DarkRed
        Write-Output "Error: $($Error[0].ToString())"
        return
    }
    Set-Content "$WR/TLSOff.cmd" -Value @'
<# : batch portion
@echo off
powershell.exe -noexit -noprofile -noexit -command "iex (${%~f0} | out-string)"
: end batch / begin powershell #>
Write-Host "TweakList Shell " -Foregroundcolor White -NoNewLine
Write-Host "(Offline)" -Foregroundcolor DarkGray -NoNewLine
Write-Host " - dsc.gg/CTT" -Foregroundcolor White -NoNewLine

'@
    $Batch = Get-Item  "$WR/TLSOff.cmd"
    Add-Content $Batch -Value $Master
    if (!$DontOpen){
        explorer.exe /select,`"$($Batch.FullName)`"
    }

}else{


    
    if ($WR -NotIn $env:PATH.Split(';')){
        Write-Error "`"$env:LOCALAPPDATA\Microsoft\WindowsApps`" is not added to path, did you mess with Windows?"
        return
    }else{
        $TLS = "$WR\TLS.CMD"
        Set-Content -Path $TLS -Value @'
@echo off
title TweakList Shell
if /I "%1" == "wr" (explorer "%~dp0" & exit)
if /I "%1" == "so" (set sophiaflag=Write-Host 'Importing Sophia Script..' -NoNewLine -ForegroundColor DarkGray;Import-Sophia)

fltmc >nul 2>&1 || (
    echo Elevating to admin..
    PowerShell.exe -NoProfile Start-Process -Verb RunAs ' %0' 2> nul || (
        echo Failed to elevate to admin, launch CMD as Admin and type in "TL"
        pause & exit 1
    )
    exit 0
)

powershell.exe -NoProfile -NoLogo -NoExit -Command ^
"if ($PWD.Path -eq \"$env:WINDIR\system32\"){cd $HOME} ;^
[System.Net.ServicePointManager]::SecurityProtocol='Tls12' ;^
Write-Host 'Invoking TweakList.. ' -NoNewLine -ForegroundColor DarkGray;^
iex(irm tl.ctt.cx);^
%SOPHIAFLAG%;^
Write-Host \"`rTweakList Shell - dsc.gg/CTT                  `n\" -Foregroundcolor White"
'@ -Force
    }
    $ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\TweakList Shell.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.IconLocation = (Get-Command powershell.exe).Source + ",0"
    $Shortcut.TargetPath = "$WR\TLS.CMD"
    $Shortcut.Save()

    # Got this from my old list of snippets, originally found this on StackOverflow, forgot link
    $bytes = [System.IO.File]::ReadAllBytes($ShortCutPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 # Set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes($ShortcutPath, $bytes)

    Write-Host "You can now type 'TLS' in Run (Windows+R) to launch it, or from your start menu"
    if (!$DontOpen){
        & explorer.exe /select,`"$("$WR\TLS.CMD")`"
    }
    
    
}
}
