function ParseTable {
    param(
        [String]$Header
    )

    $ret = [Ordered]@{}

    ForEach($Line in ($Header -Split "`n")){
        $Key, $Value = $Line -Split ': '

        if ((!$Key -or !$Value) -or ($Value -isnot [String])){
            Write-Host "Skipping: $Line" -ForegroundColor Red
            continue
        }

        if ($Value -Like '*, *'){
            $Value = $Value -split ', '
        }
        $ret.$Key = $Value
    }
    return $ret
}


Set-Location $PSScriptRoot

$Manifests = [System.Collections.ArrayList]@()

Get-ChildItem ./modules -Recurse -Include "*.ps1" | ForEach-Object {

    Remove-Variable -Name Failed, HelpInfo, Entries, FuncName, Manifest, Parameters, Description -ErrorAction Ignore
    $FuncName = $PSItem.BaseName # E.g 'Optimize-LunarClient'

    Try {
        . $PSItem -ErrorAction Stop
        $HelpInfo = Get-Help $FuncName -ErrorAction Stop
    } Catch {
        $_
        Write-Warning "Failed to get help info from $FuncName, skipping"
    }

    if ($HelpInfo.Description){ # .DESCRIPTION


        $Manifest = [Ordered]@{}
        $Manifest += @{
            Name = $FuncName
            Description = $HelpInfo.Description.Text
            Parameters = [System.Collections.ArrayList]@()
            Path = $PSItem.FullName.TrimStart($PSScriptRoot)
        }

        if ($HelpInfo.details){ # .SYNOPSIS
            # Used to store info in a 'Key: Value' pattern 

            $Entries = $HelpInfo.details.description.text -split "`n" | Where-Object {$PSItem -Like "*: *"}

            ForEach($Entry in $Entries){
                $Colons = $Entry | Select-String -Pattern ":" -AllMatches
                if ($Colons.Matches.Count -gt 1){ # Triple checking :)
                    continue
                }
                $Key, $Value = $Entry -split ": "
                if ($Value -Like "*, *"){
                    $Value = $Value -split ', '
                }
                $Manifest.$Key = $Value
            }
        }
        if(!$Manifest."Display Name"){
            $Manifest."Display Name" = $FuncName -replace '-',' '
        }

        ForEach($Parameter in $HelpInfo.Parameters.Parameter){

            $Description = ($Parameter.Description.Text -split "`n" | Where-Object {$PSItem -NotLike "//*"}) -join "`n"

            if ($Description){ # Therefore it has been documented and shall be added to the manifest

                $ParamToAdd = [Ordered]@{} # Mind it's name, couldn't also have named it Parameter
                $ParamToAdd += @{
                    Name = $Parameter.Name
                    Description = $Description
                    Type = $Parameter.type.name
                }


                $ValidateSets = (Get-Command $FuncName).Parameters.$($Parameter.Name).Attributes.ValidValues
                if ($ValidateSets){
                    $ParamToAdd += @{
                        ValidateSet = $ValidateSets
                    }
                }


                $Manifest.Parameters += $ParamToAdd
            }
        }
        $Manifests += $Manifest
    }
}
Write-Host ($Manifests | ConvertTo-Json -Depth 15)