# Made by Aetopia

function Get-NVIDIADriver {
    [alias('gnvd')]
    param(
        [String]$DriverLink, # Use your own driver link, it must be direct (no google drive)
        [Switch]$Minimal,    # If you want to use 7-Zip to extract and strip the driver
        [Switch]$GetLink,    # Returns the download link
        [Switch]$OpenLink    # Opens the download link in your default browser
    )

    if (-Not($DriverLink)){

        $File = Invoke-RestMethod 'https://www.nvidia.com/Download/processFind.aspx?psid=101&pfid=845&osid=57&lid=1&whql=1&ctk=0&dtcid=1'
        $GameReadyVersions = @()
        foreach ($Line in $File.Split('`n')){
            if ($Line -match "<td class=""gridItem"">*.*</td>") {
                $Version = $Line.Split('>')[5].Split('<')[0]
                $GameReadyVersions += $Version 
            }
        }
        $Version = $GameReadyVersions | Select-Object -First 1
    
        $DriverFile = "$env:TEMP\NVIDIA Driver - Game Ready - $Version.exe"
    
        $DriverLink = "https://international.download.nvidia.com/Windows/$Version/$Version-desktop-win10-win11-64bit-international-dch-whql.exe"
    
    }elseif($DriverLink){

        $DriverFile = "$env:TEMP\NVIDIA Driver - (Custom DL Link).exe"
    }

    # If any of these two args are used this function is simply a NVIDIA driver link parser
    if ($GetLink){return $DriverLink}
    elseif($OpenLink){Start-Process $DriverLink;return}

    Try {
        $DriverSize = (Invoke-WebRequest -Useb $DriverLink -Method Head).Headers.'Content-Length'
    } Catch {
        Write-Host "Failed to parse driver size (Invalid URL?):" -ForegroundColor DarkRed
        Write-Host $_.Exception.Message -ForegroundColor Red
        return
    }
    $DriverSize = [int]($DriverSize/1MB)
    Write-Host "Downloading NVIDIA Driver $Version ($DriverSize`MB)..." -ForegroundColor Green

    curl.exe -L -# $DriverLink -o $DriverFile

    if ($Minimal){

        $Components = @(
            "Display.Driver"
            "NVI2"
            "EULA.txt"
            "ListDevices.txt"
            "GFExperience/*.txt"
            "GFExperience/locales"
            "GFExperience/EULA.html"
            "GFExperience/PrivacyPolicy"
            "setup.cfg"
            "setup.exe"
        )
        
        $7z = Get-7zPath

        Write-Outp "Unpacking driver package with minimal components..."
        $Folder = "$env:TEMP\7z-$(Get-Item $DriverFile | Select-Object -ExpandProperty BaseName)"
        Invoke-Expression "& `"$7z`" x -bso0 -bsp1 -bse1 -aoa `"$DriverFile`" $Components -o`"$Folder`""
        Get-ChildItem $Folder -Exclude $Components | Remove-Item -Force -Recurse
        
        $CFG = Get-Item (Join-Path $Folder setup.cfg)
        $XML = @(
            '		<file name="${{EulaHtmlFile}}"/>'
            '		<file name="${{FunctionalConsentFile}}"/>'
            '		<file name="${{PrivacyPolicyFile}}"/>'
        )
        (Get-Content $CFG) | Where-Object {$_ -NotIn $XML} | Set-Content $CFG

        $setup = Join-Path $Folder setup.exe
    }else{
        $setup = $DriverFile
    }

    Write-Host "Launching the installer, press any key to continue and accept the UAC"
    Write-Verbose $setup
    PauseNul
    Start-Process $setup -Verb RunAs

}