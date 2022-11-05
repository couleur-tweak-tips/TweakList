function ParseTable {
    param(
        $Header
    )

    $Header = $Header -Split "`n"

    $ret = [Ordered]@{}

    $KeyValues   = $Header | Where-Object {$_ -Like "*: *"}
    $Description = $Header | Where-Object {$_ -NotLike "*: *"}
    
    ForEach($Line in $KeyValues){
        $Key, $Value = $Line -Split ': '

        if ((!$Key -or !$Value) -or ($Value -isnot [String])){
            Write-Host "Skipping: $Line" -ForegroundColor Red
            continue
        }

        if ($Value -Like '*; *'){
            $Value = $Value -split '; '
        }
        $ret.$Key = $Value
    }

    return @{
        Description = $Description
        KeyValues = $ret
    }
}


Set-Location $PSScriptRoot

$Manifests = [System.Collections.ArrayList]@()

Get-ChildItem ./modules -Recurse -Include "*.ps1" | ForEach-Object {

    Remove-Variable -Name Parsed, Failed, HelpInfo, Entries, FuncName, Manifest, Parameters, Description -ErrorAction Ignore
    $FuncName = $PSItem.BaseName # E.g 'Optimize-LunarClient'

    Try {
        . $PSItem -ErrorAction Stop
        $HelpInfo = Get-Help $FuncName -ErrorAction Stop
    } Catch {
        $_
        Write-Warning "Failed to get help info from $FuncName, skipping"
    }

    if ($HelpInfo.Description){ # .DESCRIPTION

        Write-Host "FullName is [$($PSItem.FullName)], root is [$PSScriptRoot]"

        $Manifest = [Ordered]@{}
        $Manifest += @{
            Name = $FuncName
            Description = $HelpInfo.Description.Text
            Parameters = [System.Collections.ArrayList]@()
            Path = $PSItem.FullName.TrimStart($PSScriptRoot)
        }

        if ($HelpInfo.details){ # .SYNOPSIS
            # Used to store info in a 'Key: Value' pattern

            #$ParsedDetails = ParseTable $HelpInfo.details.description.text
            $Parsed = (ParseTable $HelpInfo.details.description.text)
            if ($Parsed.KeyValues){
                $Manifest += $Parsed.KeyValues
            }
            if ($Parsed.Description){
                $Manifest.Description += ($Parsed.Description -join "`n")
            }
            if ($null -eq $Manifest.Description){
                $Manifest.Remove('Description')
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
                    # Description = $Description
                    Type = $Parameter.type.name
                }
                $Parsed = (ParseTable $Description)
                if ($Parsed.KeyValues){
                    $ParamToAdd.KeyValues = $Parsed.KeyValues
                }
                $ParamToAdd.Description = $Parsed.Description

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

$Manifests | ConvertTo-Json -Depth 15 | Out-File ./Manifests.json
