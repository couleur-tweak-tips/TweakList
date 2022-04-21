function Check-XMP {
    Write-Host "Checking RAM.." -NoNewline
    $PhysicalMemory = Get-CimInstance -ClassName Win32_PhysicalMemory
    $RamSpeed = $PhysicalMemory.Speed | Select-Object -First 1 # In MHz
    $IsDesktop = $null -eq (Get-CimInstance -ClassName Win32_Battery) # No battery = not a laptop (in some very rare cases that may fail but whatever it's accurate enough)
    $IsDDR4 = ($PhysicalMemory.SMBIOSMemoryType | Select-Object -First 1) -eq 26 # DDR4 = 26, DDR3 = 24
    switch((Get-CimInstance -ClassName CIM_Processor).Manufacturer){
        {$PSItem -Like "*AMD*" -or $PSItem -Like "*Advanced Micro*"}{$RamOCType = 'DOCP'}
        default{$RamOCType = 'XMP'} # Whatever else it is, it's preferably XMP
    }
    if (($RamSpeed -eq 2133) -and $IsDesktop -and $IsDDR4){
        Write-Output @"
`rYour RAM is running at the default DDR4 RAM speed of 2133 MHz.
Check if your RAM allows running at a higher speed, and if yes, turn on $RamOCType in the BIOS
"@
    }else{
        Write-Output "`rCould not determine the need for XMP/DOCP"
    }
    if ($RamSpeed){"- Your RAM speed is $RamSpeed MHz"}
    if ($null -ne $IsDesktop){"- You're on a desktop: $IsDesktop"}
    if ($null -ne $IsDDR4){"- Your RAM is DDR4: $IsDDR4"}
}

