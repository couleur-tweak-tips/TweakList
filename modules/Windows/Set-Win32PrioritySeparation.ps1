function Set-Win32PrioritySeparation {
    param(
        [int]$DWord
    )

    $Path = 'REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl'
    $current = (Get-ItemProperty $Path).Win32PrioritySeparation

    Set-ItemProperty -Path ($Path).Win32PrioritySeparation -Value $Value -Type DWord -Force -ErrorAction Inquire

    Write-Verbose "Set-Win32ProritySeparation: Changed from $current to $((Get-ItemProperty $Path).Win32PrioritySeparation)"

}

