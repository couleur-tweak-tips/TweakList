function Get-FunctionContent {
    [alias('gfc')]
    param([Parameter()][String]$FunctionName)
    if ((Get-Command $FunctionName).ResolvedCommand){
        Write-Verbose "Switching from alias $FunctionName to function $(((Get-Command $FunctionName).ResolvedCommand).Name)"
        $FunctionName = ((Get-Command $FunctionName).ResolvedCommand).Name
    }
    return (Get-Command $FunctionName).ScriptBlock
}