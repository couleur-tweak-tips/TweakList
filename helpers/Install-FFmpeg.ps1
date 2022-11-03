function Install-FFmpeg {

    $IsFFmpegScoop = (Get-Command ffmpeg -Ea Ignore).Source -Like "*\shims\*"

    if(Get-Command ffmpeg -Ea Ignore){

        $IsFFmpeg5 = (ffmpeg -hide_banner -h filter=libplacebo) -ne "Unknown filter 'libplacebo'."

        if (-Not($IsFFmpeg5)){

            if ($IsFFmpegScoop){
                Get Scoop
                scoop update ffmpeg
            }else{
                Write-Warning @"
An old FFmpeg installation was detected @ ($((Get-Command FFmpeg).Source)),

You could encounter errors such as:
- Encoding with NVENC failing (in simple terms not being able to render with your GPU)
- Scripts using new filters (e.g libplacebo)

If you want to update FFmpeg yourself, you can remove it and use the following command to install ffmpeg and add it to the path:
iex(irm tl.ctt.cx);Get FFmpeg

If you're using it because you prefer old NVIDIA drivers (why) here be dragons!
"@
pause
                
            }
            
        }
                
    }else{
        Get Scoop
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
