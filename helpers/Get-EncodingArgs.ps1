
function Get-EncodingArgs{
    [alias('genca')]
    param(
        [String]$Resolution = '3840x2160',
        [Switch]$Silent,
        [Switch]$EzEncArgs
    )

Install-FFmpeg

$DriverVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}_Display.Driver" -ErrorAction Ignore).DisplayVersion
    if ($DriverVersion){ # Only triggers if it parsed a NVIDIA driver version, else it can probably be an NVIDIA GPU
        if ($DriverVersion -lt 477.41){ # Oldest NVIDIA version capable
        Write-Warning "Outdated NVIDIA Drivers detected ($DriverVersion), you won't be able to encode using NVENC util you update them."
    }
}

$EncCommands = [ordered]@{
    'HEVC NVENC' = 'hevc_nvenc -rc vbr  -preset p7 -b:v 400M -cq 19'
    'H264 NVENC' = 'h264_nvenc -rc vbr  -preset p7 -b:v 400M -cq 16'
    'HEVC AMF' = 'hevc_amf -quality quality -qp_i 16 -qp_p 18 -qp_b 20'
    'H264 AMF' = 'h264_amf -quality quality -qp_i 12 -qp_p 12 -qp_b 12'
    'HEVC QSV' = 'hevc_qsv -preset veryslow -global_quality:v 18'
    'H264 QSV' = 'h264_qsv -preset veryslow -global_quality:v 15'
    'H264 CPU' = 'libx264 -preset slow -crf 16 -x265-params aq-mode=3'
    'HEVC CPU' = 'libx265 -preset medium -crf 18 -x265-params aq-mode=3:no-sao=1:frame-threads=1'
}

$EncCommands.Keys | ForEach-Object -Begin {
    $script:shouldStop = $false
} -Process {
    if ($shouldStop -eq $true) { return }
    Invoke-Expression "ffmpeg.exe -loglevel fatal -f lavfi -i nullsrc=$Resolution -t 0.1 -c:v $($EncCommands.$_) -f null NUL"
    if ($LASTEXITCODE -eq 0){
        $script:valid_args = $EncCommands.$_
        $script:valid_ezenc = $_

        if ($Silent){
            Write-Host ("Found compatible encoding settings using $PSItem`: {0}" -f ($EncCommands.$_)) -ForegroundColor Green
        }
        $shouldStop = $true # Crappy way to stop the loop since most people that'll execute this will technically be parsing the raw URL as a scriptblock
    }
}

if (-Not($script:valid_args)){
    Write-Host "No compatible encoding settings found (should not happen, is FFmpeg installed?)" -ForegroundColor DarkRed
    Get-Command FFmpeg -Ea Ignore
    pause
    return
}

if ($EzEncArgs){
    return $script:valid_ezenc
}else{
    return $valid_args
}

}