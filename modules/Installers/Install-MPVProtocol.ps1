function Install-MPVProtocol {
    param(
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $VideoPlayerFilePath
    )

if (!(Test-Admin)){
    "PowerShell NEEDS to run as Adminisrator in order to create the protocol handler"
    return
}


if ((Get-Command mpv -Ea 0) -and (Get-Command mpvnet -Ea 0)){
    "Would you like mpv:// links to open with MPV or MPV.net?"
    $Answer = Read-Host "Answer"
    while ($answer -notin 'mpv','mpv.net','mpvnet','exit'){
        "Answer must be mpv / mpvnet, type exit to quit"
    }
    switch ($Answer) {
        'exit'{return}
        {$_ -in 'mpvnet','mpv.net'}{$MPV = (Get-Command mpvnet.exe).Source}
        'mpv'{$MPV = (Get-Command mpv.exe).Source}
    }
}elseif(Get-Command mpv -Ea 0){
    "Using default MPV"
    $MPV = (Get-Command mpv.exe).Source
}elseif(Get-Command mpvnet -Ea 0){
    Write-Warning "Using MPV.net since MPV was not found (not added to path?)"
    $MPV = (Get-Command mpvnet.exe).Source
}else{
    return "MPV or MPV.net couldn't be found, please install MPV / MPV.net"
}

New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ea SilentlyContinue | Out-Null
New-Item -Path "HKCR:" -Name "mpv" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\mpv" -Name "(Default)" -Value '"URL:mpv Protocol"' | Out-Null
Set-ItemProperty -Path "HKCR:\mpv" -Name "URL Protocol" -Value '""' | Out-Null
New-Item -Path "HKCR:\mpv" -Name "shell" -Force | Out-Null
New-Item -Path "HKCR:\mpv\shell" -Name "open" -Force | Out-Null
New-Item -Path "HKCR:\mpv\shell\open" -Name "command" -Force | Out-Null
#Old command: "C:\ProgramData\CTT\mpv-protocol\mpv-protocol-wrapper.cmd" "%1"
$Command = "cmd /c title MPV && powershell -ep bypass -NoProfile `"& \`"$MPV\`" ('%1' -replace 'mpv://https//','https://')`""
Set-ItemProperty -Path "HKCR:\mpv\shell\open\command" -Name "(Default)" -Value  $Command | Out-Null

Write-Output "Added the registry keys to handle mpv protocol and redirect to wrapper!"

}