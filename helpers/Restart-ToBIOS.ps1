function Restart-ToBIOS {
    
    Remove-Variable -Name Choice -Ea Ignore

    while ($Choice -NotIn 'y','yes','n','no'){
        $Choice = Read-Host "Restart to BIOS? (Y/N)"
    }

    if ($Choice -in 'y','yes'){
        shutdown /fw /r /t 0
    }
    
}