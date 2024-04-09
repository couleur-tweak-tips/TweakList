# Func to set defualt browser
function Set-DefaultBrowser {
    param (
        [string]$BrowserName
    )

    # Change reg value based on browser
    switch ($BrowserName) {
        "Chrome" { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -Name "Progid" -Value "ChromeHTML" }
        "Firefox" { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -Name "Progid" -Value "FirefoxURL" }
        "Brave" { Set-ItemProperty} - Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -Name "Progid" -Value "BraveHTML" } 
        # Add more browsers here
        Default { Write-Host "Unsupported browser." }
    }
}

# Select the browser
$selectedBrowser = Read-Host "Enter the name of the browser you want to set as default (e.g., Chrome, Firefox)"

# Call the function to set the default browser
Set-DefaultBrowser -BrowserName $selectedBrowser
