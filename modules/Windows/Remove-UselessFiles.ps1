function Remove-UselessFiles {
    
    @(
        "$env:TEMP"
        "$env:WINDIR\TEMP"
        "$env:HOMEDRIVE\TEMP"
    ) | ForEach-Object { Remove-Item (Convert-Path $_\*) -Force -ErrorAction SilentlyContinue }

}