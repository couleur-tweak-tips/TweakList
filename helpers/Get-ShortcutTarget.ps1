function Get-ShortcutTarget {
    [alias('gst')]

    param([String]$ShortcutPath)

    Try {
        $null = Get-Item $ShortcutPath -ErrorAction Stop
    } Catch {
        throw
    }
    
    return (New-Object -ComObject WScript.Shell).CreateShortcut($ShortcutPath).TargetPath
}