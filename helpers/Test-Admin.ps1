function Test-Admin {
    [CmdletBinding()]
    param ()
    
    if ($IsLinux -or $IsMacOS) {
        # If sudo-ing or logged on as root, returns user ID 0
        $idCmd = (Get-Command -Name id).Source
        [int64] $idResult = & $idCmd -u
        $idResult -eq 0
    }
    else {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        (New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }
}