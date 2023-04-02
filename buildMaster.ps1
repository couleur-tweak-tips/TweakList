[CmdletBinding()]
param(
    [Switch]$Write, # Returns it instead of importing it
    [String]$Directory = $PSScriptRoot
)
if (!$Directory) {
    Write-Warning "No directory was passed, defaulting to $($PWD.Path)"
    pause
}
else {
    Push-Location $Directory
}


$FunctionCount = 0

$Master = [System.Text.StringBuilder]::new(@"
using namespace System.Management.Automation # Required by Invoke-NGENpsosh
Remove-Module TweakList -ErrorAction Ignore
New-Module TweakList ([ScriptBlock]::Create({

"@)

Get-ChildItem ./modules, ./helpers -Recurse -File | ForEach-Object {
    switch ($_) {
        { $_.Extension -eq '.ps1' } {
            Write-Verbose "Dot-sourcing $_"
            . $_.FullName
            # Wait-Debugger
            try {
                Get-Command $_.BaseName -CommandType Function -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "$_ has mismatched basename/function declared" -ForegroundColor Red
                break
            }
            $Master.Append([System.Environment]::NewLine + (Get-Content $_ -Raw)) | Out-Null
            $FunctionCount++
        }
    } }

$Master += @"

Export-ModuleMember * -Alias *
})) | Import-Module -DisableNameChecking -Global
"@

$Master = $Master -join [System.Environment]::NewLine

if (!$Write) {
    Write-Host "Imported $($FunctionCount.Count) functions"
    Invoke-Expression $Master
}
else {
    return $Master
}

Pop-Location
