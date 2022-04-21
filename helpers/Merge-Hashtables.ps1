<# Here's some example hashtables you can mess with:

$Original = @{ # Original settings
    potato = $true
    avocado = $false
}

$Patch = @{ # Fixes
    avocado = $true
}

#>
function Merge-Hashtables {
    param(
        [Switch]$ShowDiff,
        [HashTable]$Original,
        [HashTable]$Patch
    )

    $Merged = @{} # Final Merged settings

    foreach($Key in $Original.Keys){ # Loops through all OG settings

        if ($Patch.$Key){ # If the setting exists in the new settings
            $Merged += @{$Key = $Patch.$Key} # Then add it to the final settings
        }else{ # Else put in the normal settings
            $Merged += @{$Key = $Original.$Key}
        }
    }
    return $Merged
}
