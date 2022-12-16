function Import-SimeonWOS {
    [CmdletBinding()]
    param(
        [Switch]$AsScriptBlock, # Return the module object instead of importing it
        [Switch]$AsTable # Return a hashtable containing name=scriptblock
        
    )
    $AST = [ScriptBlock]::Create((
        Invoke-RestMethod https://github.com/simeononsecurity/Windows-Optimize-Debloat/raw/main/sos-optimize-windows.ps1
        )).Ast.FindAll({
            param ($node)
            $node.GetType().Name -eq 'CommandAst'
        }, $true) # Grabs each function
    
    $Jobs = $AST | Where-Object {$_.CommandElements.Value -contains "Start-Job"}
    
    $Functions = [Ordered]@{}
    $Jobs | ForEach-Object {
        $Key = ($_.CommandElements | Where-Object StringConstantType -eq "DoubleQuoted").Value
        $Value = [scriptblock]::Create($_.CommandElements.ScriptBlock.Extent.Text)
        $Functions += @{$Key=$Value}
    }

    if ($AsTable){
        return $Functions
    }
    $ModuleBlock = [ScriptBlock]::Create((
        $Functions.Keys | ForEach-Object {
            $FuncName = $_
            ForEach ($Verb in (Get-Verb).Verb){
                $FuncName = $FuncName -replace "^$Verb ", "$Verb-"
            }
            $FuncName = $FuncName -replace " ", ""
            "function $FuncName$($Functions.$_)`n`n"
    }))
    if ($AsScriptBlock){
        return $ModuleBlock
    }
    New-Module -Name "SimeonWOS (TL)" -ScriptBlock $ModuleBlock | Import-Module -Global
}

