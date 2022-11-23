function New-ContextMenu {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Text,
        [Parameter(Mandatory = $true)]
        [Array]$Extensions,
        [Parameter(Mandatory = $true)]
        [String]$Command,
        
        [String]$Icon
    ) # Text Extensions Command are all mandatory, though Icon is not and must be an existing .ico path

    if (!(Test-Admin)){
        return "Admin priviledges required (touching root class registry keys)"
    }

    ForEach($Extension in $Extensions){
        
        $shellpath = "REGISTRY::HKEY_CLASSES_ROOT\SystemFileAssociations\$Extension\shell"

        if (-Not(Test-Path $shellpath)){
            New-Item -Item Directory $shellpath -ErrorAction Stop | Out-Null
            $Item = "item0"
        }else{
            $Items = ((Get-ChildItem "$shellpath").PSChildName | 
            Where-Object {$PSItem -Like "Item*"}) -replace 'Item',''
            if ($items){
                $Item = "item" + ([int]$Items+1)
            } else{$Item = "item0"}
            Write-Host "Item is $item since there items: $items"
        }
        if (-Not(Test-Path "$shellpath\$Item")){
            New-Item -Item Directory "$shellpath\$Item" -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "$shellpath\$Item" -Name "MUIVerb" -Value $Text
        if ($icon){
            Set-ItemProperty -Path "$shellpath\$Item" -Name "Icon" -Value "$icon"
        }

        if (-Not(Test-Path "$shellpath\$Item\command")){
            New-Item -Item Directory "$shellpath\$Item\command" -ErrorAction Stop | Out-Null
        }
        Set-Item -Path "$shellpath\$Item\command" -Value "$command `"%L`""
    }
}