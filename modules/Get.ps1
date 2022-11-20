# This function centralizes most of what you can download/install on CTT
# Anything it doesn't find in that switch ($App){ statement is passed to scoop
$global:SendTo = [System.Environment]::GetFolderPath('SendTo')
function Get {
    [alias('g')] # minimalism at it's finest
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [Array]$Apps,
        [Switch]$DryRun
    )

    $FailedToInstall = $null # Reset that variable for later
    if ($Apps.Count -eq 1 -and (($Apps[0] -Split '\r?\n') -gt 1)){
        $Apps = $Apps[0] -Split '\r?\n'
    }
    if ($DryRun){
        ForEach($App in $Apps){
            "Installing $app."
        }
        return
    }

    ForEach($App in $Apps){ # Scoop exits when it throws

        switch ($App){
            'nvddl'{Get-ScoopApp utils/nvddl}
            {$_ -in 'Remux','Remuxer'}{
                Invoke-RestMethod https://github.com/couleurm/couleurstoolbox/raw/main/7%20FFmpeg/Old%20Toolbox%20scripts/Remux.bat -Verbose |
                Out-File "$SendTo\Remux.bat"

            }
            {$_ -in 'RemuxAVI','AVIRemuxer'}{
                Invoke-RestMethod https://github.com/couleurm/couleurstoolbox/raw/main/7%20FFmpeg/Old%20Toolbox%20scripts/Remux.bat -Verbose |
                Out-File "$SendTo\Remux - AVI.bat"
                $Content = (Get-Content "$SendTo\Remux - AVI.bat") -replace 'set container=mp4','set container=avi'
                Set-Content "$SendTo\Remux - AVI.bat" $Content
            }
            {$_ -in 'Voukoder','vk'}{Install-Voukoder }
            'Upscaler'{

                Install-FFmpeg 
                Invoke-RestMethod 'https://github.com/couleur-tweak-tips/utils/raw/main/Miscellaneous/CTT%20Upscaler.cmd' |
                Out-File (Join-Path ([System.Environment]::GetFolderPath('SendTo')) 'CTT Upscaler.cmd') -Encoding ASCII -Force
                Write-Host @"
CTT Upscaler has been installed,
I strongly recommend you open settings to tune it to your PC, there's lots of cool stuff to do there!
"@ -ForegroundColor Green

            }
            {$_ -In 'QualityMuncher','qm'}{
                Install-FFmpeg 

                Invoke-RestMethod 'https://raw.githubusercontent.com/Thqrn/qualitymuncher/main/Quality%20Muncher.bat' |
                Out-File (Join-Path ([System.Environment]::GetFolderPath('SendTo')) 'Quality Muncher.bat') -Encoding ASCII -Force

                Invoke-RestMethod 'https://raw.githubusercontent.com/Thqrn/qualitymuncher/main/!!qualitymuncher%20multiqueue.bat' |
                Out-File (Join-Path ([System.Environment]::GetFolderPath('SendTo')) '!!qualitymuncher multiqueue.bat') -Encoding ASCII -Force

            }

            'Scoop'{Install-Scoop }
            'FFmpeg'{Install-FFmpeg }

            {$_ -in 'CRU','custom-resolution-utility'}{Get-ScoopApp extras/cru}
            {$_ -in 'wt','windowsterminal','windows-terminal'}{Get-ScoopApp extras/windows-terminal}
            {$_ -in 'np++','Notepad++','notepadplusplus'}{Get-ScoopApp extras/notepadplusplus}
            {$_ -in 'DDU','DisplayDriverUninstaller'}{Get-ScoopApp extras/ddu}
            {$_ -in 'Afterburner','MSIAfterburner'}{Get-ScoopApp utils/msiafterburner}
            {$_ -in 'Everything','Everything-Alpha','Everything-Beta'}{Get-ScoopApp extras/everything-alpha}
            {$_ -In '7-Zip','7z','7Zip'}{Get-ScoopApp 7zip}
            {$_ -In 'Smoothie','sm'}{Install-FFmpeg ;Get-ScoopApp utils/Smoothie}
            {$_ -In 'OBS','OBSstudio','OBS-Studio'}{Get-ScoopApp extras/obs-studio}
            {$_ -In 'UTVideo'}{Get-ScoopApp utils/utvideo}
            {$_ -In 'Nmkoder'}{Get-ScoopApp utils/nmkoder}
            {$_ -In 'Librewolf'}{Get-ScoopApp extras/librewolf}
            {$_ -In 'ffmpeg-nightly'}{Get-ScoopApp versions/ffmpeg-nightly}
            {$_ -In 'Graal','GraalVM'}{Get-ScoopApp utils/GraalVM}
            {$_ -In 'DiscordCompressor','dc'}{Install-FFmpeg ;Get-ScoopApp utils/discordcompressor}
            {$_ -In 'Moony','mn'}{if (-Not(Test-Path "$HOME\.lunarclient")){Write-Warning "You NEED Lunar Client to launch it with Moony"};Get-ScoopApp utils/Moony}
            {$_ -In 'TLShell','TLS'}{Get-TLShell }
            default{Get-ScoopApp $App}
        }
        Write-Verbose "Finished installing $app"

    }
    if ($FailedToInstall){
        
        Write-Host "[!] The following apps failed to install (scroll up for details):" -ForegroundColor Red
        $FailedToInstall
    }
}