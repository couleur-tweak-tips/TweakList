[CmdletBinding()]
param(
    [Switch]$Import
)

if (!$PSScriptRoot){
    throw "ya need a root for the script to know where to build tl"
}else {
    Push-Location $PSScriptRoot
}

$Members = [System.Collections.ArrayList]@()
$Content = [System.Collections.ArrayList]@(@"
using namespace System.Management.Automation
New-Module -Name "TweakList" -ScriptBlock ([ScriptBlock]::Create({
#region Master`n
"@)

Get-ChildItem modules, helpers -Recurse | ForEach-Object {

    if ($_.Extension -eq '.ps1'){
        try {
            . $_.FullName -ErrorAction Stop
            Get-Command $_.BaseName -CommandType Function -ErrorAction Stop | Out-Null
        } catch {
            $_
            throw
        }
        $Content += (Get-Content $_.FullName -Raw -Verbose) #, "Export-ModuleMember $($_.BaseName) -Alias *"
        $Members.Add($_.BaseName) | Out-Null
    }
}
$Content += @"
`n#endregion
Export-ModuleMember $($Members -join ", ") -Alias *
})) | Import-Module -DisableNameChecking -Global
"@
if ($Import){
    & ([ScriptBlock]::Create($Content))
}else{
    Set-Content -Value $Content -Path ./MasterDev.ps1
}

Pop-Location
