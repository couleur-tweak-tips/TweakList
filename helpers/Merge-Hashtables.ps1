<#
$Original = @{
    lets = 'go'
    Sub = @{
      Foo =  'bar'
      big = 'ya'
    }
    finish = 'fish'
}
$Patch = @{
    lets = 'arrive'
    Sub = @{
      Foo =  'baz'
    }
    finish ='cum'
}
#>
function Merge-Hashtables {
    param(
        $Original,
        $Patch
    )
    $Merged = @{} # Final Merged settings

    if (!$Original){$Original = @{}}

    if ($Original.GetType().Name -in 'PSCustomObject','PSObject'){
        $Temp = [ordered]@{}
        $Original.PSObject.Properties | ForEach-Object { $Temp[$_.Name] = $_.Value }
        $Original = $Temp
        Remove-Variable Temp #fck temp vars
    }

    foreach ($Key in [object[]]$Original.Keys) {

        if ($Original.$Key -is [HashTable]){
            $Merged.$Key += [HashTable](Merge-Hashtables $Original.$Key $Patch.$Key)
            continue
        }

        if ($Patch.$Key -and !$Merged.$Key){ # If the setting exists in the patch
            $Merged.Remove($Key)
            if ($Original.$Key -ne $Patch.$Key){
                Write-Verbose "Changing $Key from $($Original.$Key) to $($Patch.$Key)"
            }
            $Merged += @{$Key = $Patch.$Key} # Then add it to the final settings
        }else{ # Else put in the unchanged normal setting
            $Merged += @{$Key = $Original.$Key}
        }
    }

    ForEach ($Key in [object[]]$Patch.Keys) {
        if ($Patch.$Key -is [HashTable] -and ($Key -NotIn $Original.Keys)){
            $Merged.$Key += [HashTable](Merge-Hashtables $Original.$Key $Patch.$Key)
            continue
        }
        if ($Key -NotIn $Original.Keys){
            $Merged.$Key += $Patch.$Key
        }
    }

    return $Merged
}

<# Here's some example hashtables you can mess with:

$Original = [Ordered]@{ # Original settings
    potato = $true
    avocado = $false
}

$Patch = @{ # Fixes
    avocado = $true
}


function Merge-Hashtables {
    param(
        [Switch]$ShowDiff,
        $Original,
        $Patch
    )

    if (!$Original){$Original = @{}}

    if ($Original.GetType().Name -in 'PSCustomObject','PSObject'){
        $Temp = [ordered]@{}
        $Original.PSObject.Properties | ForEach-Object { $Temp[$_.Name] = $_.Value }
        $Original = $Temp
        Remove-Variable Temp #fck temp vars
    }

    $Merged = @{} # Final Merged settings

    foreach($Key in $Original.Keys){ # Loops through all OG settings
        $Merging = $True

        if ($Patch.$Key){ # If the setting exists in the new settings
            $Merged += @{$Key = $Patch.$Key} # Then add it to the final settings
        }else{ # Else put in the normal settings
            $Merged += @{$Key = $Original.$Key}
        }
    }
    foreach($key in $Patch.Keys){ # If Patch has hashtables that Original does not
        if (!$Merged.$key){
            $Merged += @{$key = $Patch.$key}
        }
    }

    if (!$Merging){$Merged = $Patch} # If no settings were merged (empty $Original), completely overwrite
    return $Merged
}

#>