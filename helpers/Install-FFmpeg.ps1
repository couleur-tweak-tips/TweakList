function Install-FFmpeg {

    Install-Scoop

    Set-ExecutionPolicy Bypass -Scope Process -Force

    [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'

    $IsFFmpegScoop = (Get-Command ffmpeg -Ea Ignore).Source -Like "*\shims\*"

    if(Get-Command ffmpeg -Ea Ignore){

        $IsFFmpeg5 = (ffmpeg -hide_banner -h filter=libplacebo)

        if (-Not($IsFFmpeg5)){

            if ($IsFFmpegScoop){
                scoop update ffmpeg
            }else{
                Write-Warning @"
An FFmpeg installation was detected, but it is not version 5.0 or higher.
If you installed FFmpeg yourself, you can remove it and use the following command to install ffmpeg and add it to the path:
scoop install ffmpeg
"@
                
            }
            
        }
                
    }else{

        $Local = ((scoop cat ffmpeg) | ConvertFrom-Json).version
        $Latest = (Invoke-RestMethod https://raw.githubusercontent.com/ScoopInstaller/Main/master/bucket/ffmpeg.json).version

        if ($Local -ne $Latest){
            "FFmpeg version installed using scoop is outdated, updating Scoop.."
            if (-not(Get-Command git -Ea Ignore)){
                scoop install git
            }
            scoop update
        }

        scoop install ffmpeg
    }
}