[Array]$Functions = @() # Makes a fresh empty array
Get-ChildItem modules -Recurse -Include *.ps1 | ForEach-Object {

    Write-Output "- $($PSItem.FullName -replace '/home/runner/work/TweakList/TweakList/modules/','')" # Cleans the output of the github actions
    $Functions += Get-Content $PSItem

}

$API = (Invoke-WebRequest -Useb  "https://api.github.com/repos/couleur-tweak-tips/TweakList/commits?per_page=1").RawContent # Get TweakList repo commit info from GitHub's API
$CommitCount = (($API -split "&page=")[2] -split '>; rel="last"')[0] # Parses the API response to get the number of commits
Write-Output "Commit count: $CommitCount"
Set-Content -Path ./Master.ps1 -Value @"
# Commit count: $($CommitCount + 1)
# This file is automatically built at every commit to add up every function to a single file, this makes it simplier to parse (aka download) and execute.
"@ -Force
Add-Content -Path ./Master.ps1 -Value $Functions -Force
