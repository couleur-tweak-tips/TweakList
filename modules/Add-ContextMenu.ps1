function Add-ToContextMenu {
    param(
        [ValidateSet(
            'SendTo',
            'TakeOwnership',
            'OpenWithOnBatchFiles'
            )]
        [Array]$Entries
    )

    if ('SendTo' -in $Entries){
        New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo -Name "(default)" -PropertyType String -Value "{7BA4C740-9E81-11CF-99D3-00AA004AE837}" -Force
    }

    if ('OpenWithOnBatchFiles' -in $Entries){
        New-Item -Path "Registry::HKEY_CLASSES_ROOT\batfile\shell\Open with\command" -Force
        Set-ItemProperty "Registry::HKEY_CLASSES_ROOT\batfile\shell\Open with\command" -Name "(Default)" -Value "{09799AFB-AD67-11d1-ABCD-00C04FC30936}" -Force

    }

    if ('TakeOwnerShip' -in $Entries){
        '*','Directory' | ForEach-Object {
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\$_\shell\runas"
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name '(Default)' -Value 'Take Ownership'
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name 'NoWorkingDirectory' -Value ''
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name 'HasLUAShield' -Value ''
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name 'Position' -Value 'Middle'
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas" -Name 'AppliesTo' -Value "NOT (System.ItemPathDisplay:=`"$env:HOMEDRIVE\`")"

            New-Item -Path "Registry::HKEY_CLASSES_ROOT\$_\shell\runas\command"
            $Command = 'cmd.exe /c title Taking ownership.. & mode con:lines=30 cols=150 & takeown /f "%1" && icacls "%1" /grant administrators:F & timeout 2 >nul'
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas\command" -Name '(Default)' -Value $Command
            New-ItemProperty -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shell\runas\command" -Name 'IsolatedCommand' -Value $Command

        }
    }

}