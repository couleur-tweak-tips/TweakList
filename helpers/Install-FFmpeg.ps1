function Install-FFmpeg {

    Install-Scoop

    Set-ExecutionPolicy Bypass -Scope Process -Force

    [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'

    $IsFFmpegScoop = (Get-Command ffmpeg -Ea Ignore).Source -Like "*\shims\*"

    if(Get-Command ffmpeg -Ea Ignore){

        $IsFFmpeg5 = (ffmpeg -hide_banner -h filter=libplacebo) -ne "Unknown filter 'libplacebo'."

        if (-Not($IsFFmpeg5)){

            if ($IsFFmpegScoop){
                scoop update ffmpeg
            }else{
                Write-Warning @"
An FFmpeg installation was detected, but libplacebo filter could not be found (old FFmpeg version?).
If you installed FFmpeg yourself, you can remove it and use the following command to install ffmpeg and add it to the path:
scoop.cmd install ffmpeg
"@
pause
                
            }
            
        }
                
    }else{

        $Scoop = (Get-Command Scoop.ps1).Source | Split-Path | Split-Path

        if (-Not(Test-Path "$Scoop\buckets\main")){
            if (-Not(Test-Path "$Scoop\apps\git\current\bin\git.exe")){
                scoop install git
            }
            scoop bucket add main
        }

        $Local = ((scoop cat ffmpeg) | ConvertFrom-Json).version
        $Latest = (Invoke-RestMethod https://raw.githubusercontent.com/ScoopInstaller/Main/master/bucket/ffmpeg.json).version

        if ($Local -ne $Latest){
            "FFmpeg version installed using scoop is outdated, updating Scoop.."
            if (-not(Test-Path "$Scoop\apps\git")){
                scoop install git
            }
            scoop update
        }

        scoop install ffmpeg
        if ($LASTEXITCODE -ne 0){
            Write-Warning "Failed to install FFmpeg"
            pause
        }
    }
}
