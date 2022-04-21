function Set-Choice ($Letters){ # Convenient function for choice.exe
    if (-Not(Test-Path "$env:windir\system32\choice.exe")){Write-Error 'Choice.exe is not present on your machine';pause;exit}
    choice.exe /C $Letters /N | Out-Null
    return $Letters[$($LASTEXITCODE - 1)]
}
