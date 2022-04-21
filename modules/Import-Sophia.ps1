<#
    .SYNOPSIS
    Scraps the latest version of Sophia for W10/11/LTSC/PS7 and invokes it, as if it were importing it as a module

    It returns all the functions as raw code, so you need to execute it with Invoke-Expression (iex)
    .EXAMPLE
    Invoke-Expression (Import-Sophia)
    # Or for short:
    ipso|iex
#>
function Import-Sophia {
    [alias('ipso')]

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
    Try
    {
    $SophiaFunctions = (Invoke-RestMethod $RawURL -ErrorAction Stop)
    } 
    Catch 
    {
        Write-Host "[!] Failed to import Sophia Script Functions, press any key to continue (may likely fail)" -ForegroundColor Red
        $PSItem
        PauseNul
    }
    While ($SophiaFunctions[0] -ne '<'){
        $SophiaFunctions = $SophiaFunctions.Substring(1) # BOM ((
    } 
    $SophiaFunctions += @'




<# IMPORT-SOPHIA / IPSO Instructions:

Did you expect this to import all Sophia Script functions by itself? Here's the correct syntax:

Invoke-Expression (Import-Sophia)

or, for short:
ipso|iex

good luck tweaklisting :) #>
'@
    return $SophiaFunctions
}