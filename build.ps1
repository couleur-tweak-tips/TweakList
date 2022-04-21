[Array]$Functions = @()
$FuncsCount = 0
Get-ChildItem helpers,modules -Recurse -Include *.ps1 | ForEach-Object {

    Write-Output "- $($PSItem.FullName -replace '/home/runner/work/TweakList/TweakList/modules','')" # Cleans the output of the github actions
    $Functions += Get-Content $PSItem
    $FuncsCount++

}

$API = (Invoke-WebRequest -Useb  "https://api.github.com/repos/couleur-tweak-tips/TweakList/commits?per_page=1").RawContent # Get TweakList repo commit info from GitHub's API
Try{
    Set-Variable -Name CommitCount -Value ([int]((($API -split "&page=")[2] -split '>; rel="last"')[0]) + 1) -ErrorAction Stop # Parses the API response to get the number of commits
} Catch {
    Write-Warning "Failed to parse commit count"
    exit 1
}

Set-Content -Path ./Master.ps1 -Value @"
# This file is automatically built at every commit to add up every function to a single file, this makes it simplier to parse (aka download) and execute.

`$CommitCount = $CommitCount
`$FuncsCount = $FuncsCount
"@ -Force

Add-Content -Path ./Master.ps1 -Value $Functions -Force

$AutoBuildSize = (Get-Item ./Master.ps1).Length / 1MB

Write-Output @"
Commit count: $CommitCount
FuncsCount: $FuncsCount
Autobuild size: $([Math]::Round($AutoBuildSize, 2))
Aotubuild lines: $((Get-Content ./Master.ps1).Count)
"@
pause