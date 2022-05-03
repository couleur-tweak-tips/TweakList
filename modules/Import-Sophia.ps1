<#
    .SYNOPSIS
    Scraps the latest version of Sophia edition weither you have W10/11/LTSC/PS7, changes all function scopes and invokes it, as if it were importing it as a module

    You can find farag's dobonhonkerosly big Sophia Script at https://github.com/farag2/Sophia-Script-for-Windows
    And if you'd like using it as a GUI, try out SophiApp:  https://github.com/Sophia-Community/SophiApp
    
    .EXAMPLE
    Import-Sophia
    # Or for short:
    ipso
#>
function Import-Sophia {
    [alias('ipso')]
    param(
        [Switch]$Write
    )

    $SophiaVer = "Sophia Script for " # This will get appended later on
    $PSVer = $PSVersionTable.PSVersion.Major

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # doesn't hurt ))

    if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName) -eq "Windows 10 Enterprise LTSC 2021")
    {
        $SophiaVer += "Windows 10 LTSC 2021 PowerShell $PSVer"
    }
        elseif ((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber -eq 17763)
    {
        $SophiaVer += "Windows 10 LTSC 2019 PowerShell $PSVer"
    }
        else
    {
        $SophiaVer += "Windows $([System.Environment]::OSVersion.Version.Major)"
        if ($PSVer -ge 7){$SophiaVer += " PowerShell $PSVer"}
    }

    $RawURL = "https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/master/Sophia%20Script/$($SophiaVer -Replace ' ','%20')/Module/Sophia.psm1"
    Write-Verbose $RawURL

    $SophiaFunctions = (Invoke-RestMethod $RawURL -ErrorAction Stop)

    While ($SophiaFunctions[0] -ne '<'){
        $SophiaFunctions = $SophiaFunctions.Substring(1) # BOM ((
    } 

    $SophiaFunctions = $SophiaFunctions -replace 'RestartFunction','tempchannge' # farag please forgive me
    $SophiaFunctions = $SophiaFunctions -replace 'function ','function global:'
    $SophiaFunctions = $SophiaFunctions -replace 'tempchange','RestartFunction'

    if ($Write){
        return $SophiaFunctions
    }else{
        Invoke-Expression $SophiaFunctions
    }

}