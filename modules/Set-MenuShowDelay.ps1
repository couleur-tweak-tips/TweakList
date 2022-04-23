# Default is 400(ms)
function Set-MenuShowDelay {
    param(
        [Int]$DelayInMs
    )
    
    Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" -Name MenuShowDelay -PropertyType String -Value $DelayInMs -Force
}