function 4K-Notifier {
    param(
        [Parameter(Mandatory)]
        [String]$Video,
        [int]$Timeout = 30
    )
    if (!$Video){
        $Video = Read-Host "Pleaste paste in the URL of the video you'd like to wait for until it hits 4K"
    }
if (Get-Command yt-dlp -Ea 0){
    $ytdl = (Get-Command yt-dlp).Source
}elseif(Get-Command youtube-dl -Ea 0){
    $ytdl = (Get-Command youtube-dl).Source
}else{
    return @"
Nor YouTube-DL or yt-dlp are installed or added to the path, please run the following command to install it:
iex(irm tl.ctt.cx);Get-ScoopApp main/yt-dlp
"@
}
''
$Finished = $null
$Attempt = 0
While (!$Finished){
    $Attempt++
    $Response = & $ytdl -F $Video
    if ($Response | Where-Object {$PSItem -Like "*3840x2160*"}){
        $Finished = $True
    }else{
        Write-Host "`rYour video has not been encoded to 4K, trying again (attempt n°$attempt) in $Timeout seconds.." -NoNewLine 
        Start-Sleep -Seconds $Timeout
        Write-Host "`rTrying again..                                                       " -NoNewLine -ForegroundColor Red
        continue
    }
}
Set-Clipboard -Value $Video
Write-Host @"

YouTubed finished processing your video, it's URL has been copied to your clipboard:
$Video
"@ -ForegroundColor Green
1..3 | ForEach-Object{
    [Console]::Beep(500,300)
    Start-Sleep -Milliseconds 100
}
}
