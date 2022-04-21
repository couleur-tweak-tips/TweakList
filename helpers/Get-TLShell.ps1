function Get-TLShell {
    param([switch]$Profile)

if ($Profile){
    

}else{

    $WR = "$env:LOCALAPPDATA\Microsoft\WindowsApps" # I've had the habit of calling this folder WR
                                                    # because it's the only folder I know that is added to path
                                                    # that you don't need perms to access.

    if ($WR -NotIn $env:PATH.Split(';')){
        Write-Error "`"$env:LOCALAPPDATA\Microsoft\WindowsApps`" is not added to path, did you mess with Windows?"
        return
    }else{
        Set-Content "$WR\TL.CMD" @"
@echo off
title TweakList Shell
fltmc >nul 2>&1 || (
    echo Elevating to admin..
    PowerShell Start-Process -Verb RunAs '%0' 2> nul || (
        echo Failed to elevate to admin, launch CMD as Admin and type in "TL"
        pause & exit 1
    )
    exit 0
)
cd "$HOME"

where.exe pwsh.exe
if "%ERRORLEVEL%"=="1" (set sh=pwsh.exe) else (set sh=powershell.exe)
%SH% -ep bypass -nologo -noexit -command [System.Net.ServicePointManager]::SecurityProtocol='Tls12';iex(irm https://github.com/couleur-tweak-tips/TweakList/releases/latest/download/Master.ps1)
"@ -Force
    }
}
}