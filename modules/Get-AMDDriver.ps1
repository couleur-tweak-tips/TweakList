function Get-AMDDriver {
    [alias('gamd')]
    param(
        [String]$DriverFilePath
    )

    if (-Not($DriverFilePath)){
        Write-Host @"
AMD does not allow automatic downloads,
go on https://www.amd.com/support and download a driver FROM THE LIST, not the automatic detection one

You can then call this function again with the -DriverFilePath parameter, example:

Get-AMDDriver -DriverFilePath 'C:\Users\$env:USERNAME\Downloads\amd-software-adrenalin-edition-22.4.1-win10-win11-april5.exe'
"@ -ForegroundColor Red
    }

    Try {
        Test-Path $DriverFilePath -PathType Leaf -ErrorAction Stop | Out-Null
    } Catch {
        "The driver file $DriverFilePath does not exist"
        exit 1
    }

    $7z = Get-7zPath
    $Folder = "$env:TMP\AMD Driver - $(Get-Random)"

    Invoke-Expression "& `"$7z`" x -bso0 -bsp1 -bse1 -aoa `"$DriverFilePath`" -o`"$Folder`""

    Remove-Item "$Folder\Packages\Drivers\Display\WT6A_INF\amd*"

    $DLLsDir = Resolve-Path "$Folder\Packages\Drivers\Display\WT*_INF\B*"

    $ToStrip = [Ordered]@{
        'ccc2_install.exe' = 'ccc2_install.exe=1'
        'atiesrxx.exe' = 'atiesrxx.exe'
        'amdlogum.exe' = 'amdlogum.exe,,,0x00004000', 'amdlogum.exe=1'
        'dgtrayicon.exe' = 'dgtrayicon.exe,,,0x00004000', 'dgtrayicon.exe=1'
        'GameManager64.dll' = 'GameManager64.dll,,,0x00004000', 'gamemanager64.dll=1'
        'amdlvr64.dll' = 'amdlvr64.dll,,,0x00004000', 'amdlvr64.dll=1'
        'RapidFireServer64.dll' = 'RapidFireServer64.dll,,,0x00004000', 'rapidfireserver64.dll=1'
        'Rapidfire64.dll' = 'Rapidfire64.dll,,,0x00004000', 'rapidfire64.dll=1'
        'atieclxx.exe' = 'atieclxx.exe,,,0x00004000', 'atieclxx.exe=1'
        'branding.bmp' = 'branding.bmp,,,0x00004000', 'branding.bmp=1'
        'brandingRSX.bmp' = 'brandingRSX.bmp,,,0x00004000','brandingrsx.bmp=1'
        'brandingWS_RSX.bmp' = 'brandingWS_RSX.bmp,,,0x00004000', 'brandingws_rsx.bmp=1'
        'GameManager32.dll' = 'GameManager32.dll,,,0x00004000', 'gamemanager32.dll=1'
        'amdlvr32.dll' = 'amdlvr32.dll,,,0x00004000', 'amdlvr32.dll=1'
        'RapidFireServer.dll' = 'RapidFireServer.dll,,,0x00004000', 'rapidfireserver.dll=1'
        'Rapidfire.dll' = 'Rapidfire.dll,,,0x00004000', 'rapidfire.dll=1'
        'amdfendr.ctz' = 'amdfendr.ctz=1'
        'amdfendr.itz' = 'amdfendr.itz=1'
        'amdfendr.stz' = 'amdfendr.stz=1'
        'amdfendrmgr.stz' = 'amdfendrmgr.stz=1'
        'amdfendrsr.etz' = 'amdfendrsr.etz=1'
        'atiesrxx.ex' = 'atiesrxx.exe=1'

        'amdmiracast.dll' = 'amdmiracast.dll,,,0x00004000', 
                            'HKR,,ContentProtectionDriverName,%REG_SZ%,amdmiracast.dll', 
                            'amdmiracast.dll=1', 
                            'amdmiracast.dll=SignatureAttributes.PETrust'

        CopyINFs = 'CopyINF = .\amdxe\amdxe.inf', 
                   'CopyINF = .\amdfendr\amdfendr.inf', 
                   'CopyINF = .\amdafd\amdafd.inf'
    }
    Remove-Item (Get-ChildItem $DLLsDir -Force | Where-Object {$_.Name -in $ToStrip.Keys}) -Force -ErrorAction Ignore

    $inf = Resolve-Path "$DLLsDir\..\U*.inf"

    (Get-Content $inf ) | Where-Object {$_ -NotIn $ToStrip.Values} | Set-Content $inf -Force

}