function RemovePackBangs {
    # Removes the exclamation bangs and spaces from all your !   PackName.zip
    param(
        [ValidateScript({
            Test-Path $_ -PathType Container
        })]
        [String]$PackFolderPath = $(if ($IsLinux){"$env:HOME/.minecraft/resourcepacks"} else {"$env:APPDATA\.minecraft\resourcepacks"})
    )

    Get-ChildItem $PackFolderPath  | ForEach-Object {

        $NewName = $_.Name.TrimStart("! ")

        if ($_.Name -ne $NewName){
            if (Test-Path -LiteralPath (Join-Path $PackFolderPath $NewName)){

                Write-Warning "Skipping renaming [$($_.Name)], copy exists with no bangs"

            } else{
                Write-Host "Renaming to $NewName" -ForegroundColor Green
                Rename-Item -Path $PSItem -NewName $NewName -Verbose
            }
        }
    } 
}
