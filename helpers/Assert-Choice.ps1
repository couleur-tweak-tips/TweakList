function Assert-Choice {
    if (-Not(Get-Command choice.exe -ErrorAction Ignore)){
        Write-Host "[!] Unable to find choice.exe (it comes with Windows, did a little bit of unecessary debloating?)" -ForegroundColor Red
        PauseNul
        exit 1
    }
}