function Get-GraalVM {
    param(
        [Switch]$Reinstall
    )

    if ((Test-Path "$env:ProgramData\GraalVM") -and !$Reinstall){
        "GraalVM is already installed, run with -Reinstall to force reinstallation"
    }
    if (-Not(Get-Command curl.exe -ErrorAction Ignore)){
        return "curl is not found (comes with windows per default?)"
    }
    Remove-Item "$env:ProgramData\GraalVM" -ErrorAction Ignore -Force -Recurse

    $URL = 'https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-21.2.0/graalvm-ce-java16-windows-amd64-21.2.0.zip'
    $SHA256 = 'DAE2511ABFF8EAD3EBC90CD9FC81A8E84B762FC91462B198C3EDDF28F81A937E'
    $Zip = "$env:TMP\GraalVM.zip"


    if (-Not(Test-Path $Zip)){
        Write-Host "Downloading GraalVM ($(Get-HeaderSize $URL)`MB).." -ForegroundColor Green
        curl.exe -# -L $URL -o"$Zip"
    }

    if ((Get-FileHash $Zip).Hash -ne $SHA256){
        return "Failed to download GraalVM (SHA256 checksum mismatch, not the expected file)"
    }

    if (Get-Command 7z -ErrorAction Ignore){

        Invoke-Expression "& `"7z`" x -bso0 -bsp1 -bse1 -aoa `"$env:TMP\GraalVM.zip`" -o`"$env:ProgramData\GraalVM`""
    } else {
        Expand-Archive -Path $Zip -Destination "$env:ProgramData\GraalVM"
    }
    Move-Item -Path "$env:ProgramData\GraalVM\graalvm-?e*\*" "C:\ProgramData\GraalVM"
}