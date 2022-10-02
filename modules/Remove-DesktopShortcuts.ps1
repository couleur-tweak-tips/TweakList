function Remove-DesktopShortcuts ($ConfirmEach){
    
    if($ConfirmEach){
        Get-ChildItem -Path "$HOME\Desktop" -Include "*.lnk" -Force | Remove-Item -Confirm
    }else{
        Get-ChildItem -Path "$HOME\Desktop" -Include "*.lnk" -Force | Remove-Item
    }
}
