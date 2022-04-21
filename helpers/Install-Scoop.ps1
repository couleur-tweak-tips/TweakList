function Install-Scoop {
    param(
        [String]$InstallDir
    )
    Set-ExecutionPolicy Bypass -Scope Process -Force

    if (-Not(Get-Command scoop -Ea Ignore)){
        
        $RunningAsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')

        if($InstallDir){
            $env:SCOOP = $InstallDir	
            [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
        }

        If (-Not($RunningAsAdmin)){
            Invoke-Expression (Invoke-RestMethod -Uri http://get.scoop.sh)
        }else{
            Invoke-Expression "& {$(Invoke-RestMethod -Uri https://get.scoop.sh)} -RunAsAdmin"
        }
    }

    Try {
        scoop -ErrorAction Stop | Out-Null
    } Catch {
        Write-Warning "Something went wrong with installing Scoop"
        ''
        Write-Host $PSItem -ForegroundColor Red
        ''
        Pause
        exit
    }
}