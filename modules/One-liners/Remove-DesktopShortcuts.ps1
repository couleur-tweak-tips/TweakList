function Remove-DesktopShortcuts ([Switch]$ConfirmEach){
    
    if($ConfirmEach){
        Get-ChildItem -Path "$HOME\Desktop" | Where-Object Extension -eq ".lnk" | Remove-Item -Confirm
    }else{
        Get-ChildItem -Path "$HOME\Desktop" | Where-Object Extension -eq ".lnk" | Remove-Item
    }
}
