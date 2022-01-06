
[Array]$Functions = @()
Get-ChildItem -Recurse -Exclude 'import.ps1' -Include *.ps1 | ForEach-Object {$Functions += Get-Content $PSItem}

$API = (Invoke-WebRequest -Useb  "https://api.github.com/repos/couleur-tweak-tips/TweakList/commits?per_page=1").RawContent
$CommitCount = (($API -split "&page=")[2] -split '>; rel="last"')[0]

$Master = Join-Path $PSScriptRoot Master.ps1

Set-Content -Path $Master -Value @"
# Commit count: $($CommitCount + 1)
# This file is automatically built at every commit to add up every function to a single file, this makes it simplier to download and execute.

"@ -Force

Add-Content -Path $Master -Value $Functions -Force
