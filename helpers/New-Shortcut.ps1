function New-Shortcut {
    param(
        [Switch]$Admin,
        [Switch]$Overwrite,
        [String]$LnkPath,
        [String]$TargetPath,
        [String]$Arguments,
        [String]$Icon
    )

    if ($Overwrite){
        if (Test-Path $LnkPath){
            Remove-Item $LnkPath
        }
    }

    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($LnkPath)
    $Shortcut.TargetPath = $TargetPath
    if ($Arguments){
        $Shortcut.Arguments = $Arguments
    }
    if ($Icon){
        $Shortcut.IconLocation = $Icon
    }

    $Shortcut.Save()
    if ((Get-Item $LnkPath).FullName -cne $LnkPath){
        Rename-Item $LnkPath -NewName (Get-Item $LnkPath).Name # Shortcut names are always underscore
    }

    if ($Admin){
    
        $bytes = [System.IO.File]::ReadAllBytes($LnkPath)
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($LnkPath, $bytes)
    }
}