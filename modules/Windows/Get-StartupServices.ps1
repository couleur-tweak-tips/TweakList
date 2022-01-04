function Get-StartupServices {

Get-Service | Where-Object -FilterScript { $_.StartType -EQ 'Automatic' } | Format-List

}