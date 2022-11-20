function FindInText{
    <#
    Recreated a simple grep for finding shit in TweakList,
    I mostly use this to check if a function/word has ever been mentionned in all my code
    #>
    param(
        [String]$String,
        $Path = (Get-Location),
        [Array]$Exclude,
        [Switch]$Recurse
    )

    $Exclude += @(
    '*.exe','*.bin','*.dll'
    '*.png','*.jpg'
    '*.mkv','*.mp4','*.webm'
    '*.zip','*.tar','*.gz','*.rar','*.7z','*.so'
    '*.pyc','*.pyd'
    )

    $Parameters = @{
        Path = $Path
        Recurse = $Recurse
        Exclude = $Exclude
    }
    $script:FoundOnce = $False
    $script:Match = $null
    Get-ChildItem @Parameters -File | ForEach-Object {
        $Match = $null
        Write-Verbose ("Checking " + $PSItem.Name)
        $Match = Get-Content $PSItem.FullName | Where-Object {$_ -Like "*$String*"}
        if ($Match){
            $script:FoundOnce = $True
            Write-Host "- Found in $($_.Name) ($($_.FullName))" -ForegroundColor Green
            $Match
        }
    }

    if (!$FoundOnce){
        Write-Host "Not found" -ForegroundColor red
    }
}