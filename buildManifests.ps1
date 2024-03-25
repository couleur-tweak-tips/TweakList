<#

    .DESCRIPTION

    Splits string-based description from hashtable-based key;values

    .EXAMPLE
    $desc, $value = Get-Metadata @"
    Hey this is a description

    key1: value1
    key2: value2
    "@
#>
function Get-Metadata ($string) {
    $desc = $string -split "`n" | Where-Object { $_ -NotLike "*: *" -and $_.trim() } | Where-Object { $_ -notlike "//*" }
    $values = $string -split "`n" | Where-Object { $_ -Like "*: *" } | Where-Object { $_ -notlike "//*" }

    $value_table = [PSCustomObject]@{}
    if ($values) {

        foreach ($line in $values) {
            [string]$key, [string]$value = ($line -split ':', 2).trim()
            if (!$key -or !$value) {
                Write-Error "Failed getting metadata from`n$($string | ConvertTo-Json -Depth 3)"
            }

            $value_table | Add-Member -MemberType NoteProperty -Name $key -Value $value
        }
    }
    else {
        $values = ""
    }
    if (!$desc) { $desc = "" }
    return @($desc, $value_table)
}


function buildManifests2 {
    param(
        $Path = (Get-ChildItem ./modules/ -File -Recurse -Include *.ps1)
    )
    $ManifestList = [PSCustomObject]::new()

    foreach($i in $Path){

        $filepath = Get-Item $i -ErrorAction Stop


        $funcName = $filepath.BaseName        
        . $filepath.FullName -ErrorAction Stop
        $HelpInfo = Get-Help $funcName -ErrorAction Stop

        $Manifest = [PSCustomObject]::new()

        $relativePath = $filepath.FullName.Replace($PSScriptRoot,'') -replace '\\', '/'

        $Manifest | Add-Member -MemberType NoteProperty -Name path -Value $relativePath
        
        
        if ($desc = $HelpInfo.description.Text) {
            # .DESCRIPTION
            
            $Manifest | Add-Member -MemberType NoteProperty -Name description -Value $desc
        }
        else {
            # function is not documented, skip
            continue
        }

        if ($null, $values = Get-Metadata $HelpInfo.details.description.Text) {
            foreach ($object in $values.psobject.properties) {
                $key, $value = $object.name, $object.value
                $Manifest | Add-Member -MemberType NoteProperty -Name $key -Value $value
            }
        }

        if (!$Manifest.display) {
            $Manifest | Add-Member -MemberType NoteProperty -Name display -Value ($FuncName -replace '-', ' ')
        }

        $Manifest | Add-Member -MemberType NoteProperty -Name parameters -Value ([PSCustomObject]::new())

        foreach ($parameter in $HelpInfo.parameters.parameter) {


            [PSCustomObject]$param = [PSCustomObject]::new()

            # if ($parameter.name -in @('misctweaks')){wait-debugger}

            if ($desc, $values = Get-Metadata $parameter.description.Text) {

                if ($desc) {
                    $param | Add-Member -MemberType NoteProperty -Name description -Value $desc
                }

                if ($values.PSObject.Properties.Count) {
                    if ($values -is [String]){
                        $values = @($values)
                    }
                    $param | Add-Member -MemberType NoteProperty -Name values -Value $values
                }
            }
            if (!$param.values) {

                if ($ValidateSets = (Get-Command $funcName).Parameters.$($Parameter.Name).Attributes.ValidValues) {
                    if ($ValidateSets -is [String]){
                        $ValidateSets = @($ValidateSets)
                    }
                    $param | Add-Member -MemberType NoteProperty -Name values -Value $ValidateSets
                }
            }
            if ($parameter.defaultValue -and $parameter.type.name -ne "Array") {
                $param | Add-Member -MemberType NoteProperty -Name default -Value $parameter.defaultValue
            }

            $param | Add-Member -MemberType NoteProperty -Name type -Value $(switch ($parameter.type.name) {
                    Array {
                        if ($param.values) {
                            "enum[]"
                        }
                        else {
                            Wait-Debugger
                        }
                    }
                    String {
                        if ($param.values) {
                            "enum"
                        }
                        else {
                            "string"
                        }
                    }
                    SwitchParameter {
                        "boolean"
                    }
                    default {
                        Write-Warning "Unknown type $()"
                    }
                })

            if ($parameter.required -eq "true") {
                $param | Add-Member -MemberType NoteProperty -Name required -Value $true
            }
            
            $Manifest.parameters | Add-Member -MemberType NoteProperty -Name $parameter.name -Value $param
        } # foreach param

        $ManifestList | Add-Member -MemberType NoteProperty -Name $funcName -Value $Manifest
    } # foreach file

    return $ManifestList
}
buildManifests2