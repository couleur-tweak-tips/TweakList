function Get-FunctionContent {
    [alias('gfc')]
    param([Parameter()][String]$FunctionName)
    return (Get-Command $FunctionName).ScriptBlock
}