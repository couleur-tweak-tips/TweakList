Function Get-MSIModeCapableDevices {
    $MSISupportedDevices = [ordered]@{}
    (Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI").Name | 
    ForEach-Object {
        (Get-ChildItem "Registry::$_\*\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties").Name | 
        Where-Object { $_.Length -ne 0 } |
        ForEach-Object {
            $Key = ($_ -Split "\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties", 2, "SimpleMatch")[0]
            $MSISupportedDevices[(Get-ItemPropertyValue "Registry::$Key" "HardwareID")[-1]] = @(
                (((Get-ItemPropertyValue "Registry::$Key" "DeviceDesc") -Split ";", 0, "SimpleMatch")[-1]),
                (Get-ItemPropertyValue "Registry::$_" "MSISupported"))
        } 
    }
    return $MSISupportedDevices
}
