Get-ChildItem | Select Name
[Array]$Functions = @() # Makes a fresh empty array
Get-ChildItem Modules -Recurse -Include *.ps1 | ForEach-Object {

$Functions += Get-Content $PSItem


} # The #region **filename** / #endregion makes 

$API = (Invoke-WebRequest -Useb  "https://api.github.com/repos/couleur-tweak-tips/TweakList/commits?per_page=1").RawContent # Pings GitHub's API
$CommitCount = (($API -split "&page=")[2] -split '>; rel="last"')[0] # Parses the API response to get the number of commits
Set-Content -Path ./Master.ps1 -Value @"
# Commit count: $($CommitCount + 1)
# This file is automatically built at every commit to add up every function to a single file, this makes it simplier to download and execute.
"@ -Force
Add-Content -Path ./Master.ps1 -Value $Functions -Force
