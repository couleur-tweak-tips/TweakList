function Get-HeaderSize {
    param(
        $URL,
        $FileName = "file"
    )
    Try {
        $Size = (Invoke-WebRequest -Useb $URL -Method Head -ErrorAction Stop).Headers.'Content-Length'
    }Catch{
        Write-Host "Failed to parse $FileName size (Invalid URL?):" -ForegroundColor DarkRed
        Write-Host $_.Exception.Message -ForegroundColor Red
        return

    }
    return [Math]::Round((($Size | Select-Object -First 1) / 1MB), 2)
    
}