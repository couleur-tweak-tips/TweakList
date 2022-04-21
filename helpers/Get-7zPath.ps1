function Get-7zPath {

    if (Get-Command 7z.exe -Ea Ignore){return (Get-Command 7z.exe).Source}

    $DefaultPath = "$env:ProgramFiles\7-Zip\7z.exe"
    if (Test-Path $DefaultPath) {return $DefaultPath}

    Try {
        $InstallLocation = (Get-Package 7-Zip* -ErrorAction Stop).Metadata['InstallLocation'] # Compatible with 7-Zip installed normally / with winget
        if (Test-Path $InstallLocation -ErrorAction Stop){
            return "$InstallLocation`7z.exe"
        }
    }Catch{} # If there's an error it's probably not installed anyways

    if (Get-Boolean "7-Zip could not be found, would you like to download it using Scoop?"){
        Install-Scoop
        scoop install 7zip
        if (Get-Command 7z -Ea Ignore){
            return (Get-Command 7z.exe).Source
        }else{
            Write-Error "7-Zip could not be installed"
            return 
        }

    }else{return}

    # leaving this here if anyone knows a smart way to implement this ))
    # $7Zip = (Get-ChildItem -Path "$env:HOMEDRIVE\*7z.exe" -Recurse -Force -ErrorAction Ignore).FullName | Select-Object -First 1

}
