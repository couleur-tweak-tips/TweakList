<#

List of commonly used Appx packages:

Windows.PrintDialog
Microsoft.WindowsCalculator
Microsoft.ZuneVideo
Microsoft.Windows.Photos

I did not add them, but you can opt in by calling the function, e.g:

    Remove-KnownAppxPackages -Add @('Windows.PrintDialog','Microsoft.WindowsCalculator')

Don't forget to surround them by a ' so PowerShell considers them as a string

#>

function Remove-KnownAppxPackages ([array]$Add,[array]$Exclude) {

    $AppxPackages = @(
        "Microsoft.Windows.NarratorQuickStart"
        "Microsoft.Wallet"
        "3DBuilder"
        "Microsoft.Microsoft3DViewer"
        "WindowsAlarms"
        "BingSports"
        "WindowsCommunicationsapps"
        "WindowsCamera"
        "Feedback"
        "Microsoft.GetHelp"
        "GetStarted"
        "ZuneMusic"
        "WindowsMaps"
        "Microsoft.Messaging"
        "Microsoft.MixedReality.Portal"
        "Microsoft.OneConnect"
        "BingFinance"
        "Microsoft.MSPaint"
        "People"
        "WindowsPhone"
        "Microsoft.YourPhone"
        "Microsoft.Print3D"
        "Microsoft.ScreenSketch"
        "Microsoft.MicrosoftStickyNotes"
        "SoundRecorder"
        
        ) | Where-Object { $_ -notin $Exclude }

        $AppxPackages += $Add # Appends the Appx packages given by the user (if any)

        if (-Not($KeepXboxPackages)){
            $AppxPackages += @(
                "XboxApp"
                "Microsoft.XboxGameOverlay"
                "Microsoft.XboxGamingOverlay"
                "Microsoft.XboxSpeechToTextOverlay"
                "Microsoft.XboxIdentityProvider"
                "Microsoft.XboxGameCallableUI"
            )
        }


        ForEach ($Package in $AppxPackages){
        
        if ($PSVersionTable.PSEdition -eq 'Core'){ # Newer PowerShell versions don't have Appx cmdlets, manually calling PowerShell to 
        
            powershell.exe -command "Get-AppxPackage `"*$Package*`" | Remove-AppxPackage"
        
        }else{
            Get-AppxPackage "*$Package*" | Remove-AppxPackage
        }
        
        }

}

