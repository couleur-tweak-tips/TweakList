function Set-Win32ProritySeparation ([int]$Value){

    $Path = 'REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl'
    $current = (Get-ItemProperty $Path).Win32PrioritySeparation
    Set-ItemProperty -Path $Path -Value $Value -Type DWord -Force -ErrorAction Inquire
    Write-Verbose "Set-Win32ProritySeparation: Changed from $current to $((Get-ItemProperty $Path).Win32PrioritySeparation)"-Verbose

}