function Block-RazerSynapse {
    Try {
        Remove-Item "C:\Windows\Installer\Razer" -Force -Recurse
    } Catch {
        "Failed to remove Razer installer folder"
        $_.Exception.Message
    }
    New-Item -ItemType File -Path "C:\Windows\Installer\Razer" -Force -ErrorAction Stop
    Write-Host "An empty file called 'Razer' in C:\Windows\Installer has been put to block Razer Synapse's auto installation"
}