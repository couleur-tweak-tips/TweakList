function Import-SycnexDebloater {
    param(
        [String]$RawPSM1 = 'https://github.com/Sycnex/Windows10Debloater/raw/master/Windows10Debloater.ps1',
        [switch]$Write
    )
    $Script = Invoke-RestMethod $RawPSM1 -ErrorAction Stop

    $FunctionData = [ScriptBlock]::Create(($Script)).
        Ast.FindAll({
            param ($node)
            $node.GetType().Name -eq 'FunctionDefinitionAst'
        }, $true)

    $FakeModule = $FunctionData | ForEach-Object {$_.Extent.Text}

    if ($Write){return $FakeModule}

    New-Module -Name "Sycnex's Debloater (TL)" -ScriptBlock ([ScriptBlock]::Create($FakeModule)) | Import-Module -DisableNameChecking

}