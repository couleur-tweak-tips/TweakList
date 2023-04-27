function Enable-Teredo {
    
    # Make the script run as admin
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
        Exit
    }

    # Get Teredo State
    $TeredoState = (Get-NetTeredoConfiguration).Type
    
    # Check if Teredo is disabled
    if($TeredoState -eq "Disabled") {

        $response = Read-Host "Teredo is disabled, would you like to enable it? (Y/N)"

        if ($response -eq "Y" -or $response -eq "y") {
            Write-Host "Enabling Teredo..."

            Set-NetTeredoConfiguration -Type EnterpriseClient
            Set-NetTeredoConfiguration -ServerName teredo.remlab.net

            Write-Host "Teredo Enabled!"
            Pause

        } else {
            Exit
        }

    } else {
        Write-Host "Teredo is already enabled!"
        Pause
    }
}