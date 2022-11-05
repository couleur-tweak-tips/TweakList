function ParseTable {
    <#

    #//Turns:
    Hello, this is my parameter's description,
    here's some useful info that will get formatted and fed in the manifests separately
    Platform: Linux; Windows
    Category: Optimizations
    #//Into:
    @{
        Description = @(
            "Hello, this is my parameter's description,"
            "here's some useful info that will get formatted and fed in the manifests separately"
        )
        KeyValues = @{
            Category = 'Optimizations'
            Platform = @('Linux', 'Windows')
        }
    }

    #>
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
        # Then such value has been properly documented and will be added to the Manifests

        $Manifest = [Ordered]@{}
        $Manifest += @{
            Name = $FuncName
            Description = $HelpInfo.Description.Text
            Parameters = [System.Collections.ArrayList]@()
            Path = $PSItem.FullName.Replace($PSScriptRoot,'')
        }

        if ($HelpInfo.details){ # .SYNOPSIS

            $Parsed = (ParseTable $HelpInfo.details.description.text)
            if ($Parsed.KeyValues){
                $Manifest += $Parsed.KeyValues
            }
            if ($Parsed.Description){
                $Manifest.Description += ($Parsed.Description -join "`n")
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
                    Required = $Parameter.required
                    # Description = $Description
                    Type = $Parameter.type.name
                }
                $Parsed = (ParseTable $Description)
                if ($Parsed.KeyValues){
                    $ParamToAdd.KeyValues = $Parsed.KeyValues
                }
                if ($Parsed.Description){
                    $ParamToAdd.Description = $Parsed.Description
                }else{
                    Write-Host "No description for parameter [$($Parameter.Name)] in function [$($Manifest.Name)]" -ForegroundColor Red
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

$Manifests | ConvertTo-Json -Depth 15 | Out-File ./Manifests.json
