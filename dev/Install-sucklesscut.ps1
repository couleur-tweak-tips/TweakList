function Install-sucklesscut {
    param(
        $CustomDIR
    )
    if ($CustomDir -and !$DIR){ # Manually installing it, not from 
        if (!(Test-Path "$CustomDir\mpv.conf")){
            Write-Host "The folder you gave needs to be the config folder of MPV" -ForegroundColor Red
            Write-Host @(
                "It should contain files such as ``mpv.conf``, ``input.conf``,"
                "and have a folder named ``scripts``"
                -join "`n")
            return
        }else{
            $DIR = (Get-Item $CustomDir).FullName
        }
    }
    "There's two ways to set up the suckless-cut.lua script:"
    ""
    "Yes - Load the script when launching it via a shortcut in Send To (simplest, recommended)"
    "No - Add it permanently in your MPV's config (requires you to know where it's located)"
    if (Get-Boolean -Message "Your choice: "){
        $Shortcut = Join-Path [System.Environment]::GetFolderPath('SendTo') 'suckless-cut.lnk'

        if (Test-Path $Shortcut){
            Remove-Item $Shortcut
        }
        
        $Parameters = @{
            Overwrite = $True
            LnkPath = $Shortcut
            TargetPath = Get-Path mpv.exe
            Arguments = "script=`"$DIR\suckless-cut.lua`""
            Icon = "$DIR\suckless-cut.icon"
        }
        New-Shortcut @Parameters
        Write-Host "Installed! Right-click any video file(s), in the Send To drop-down select ``suckless-cut``" -ForegroundColor Green
    }else {
        if (!$CustomDIR){

            $RootFolder = if ($MPVPath = Get-Path mpv){ # Assign $MPVPath if it exists
                $MPVPath | Split-Path # $RootFolder will hold this value 
            } else{ # or else this one
                $env:HOMEDRIVE
            }

            Add-Type -AssemblyName Windows.Forms
            # Create an object and properties
            $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            $FolderBrowser.Description = "Select your MPV config folder"
            $FolderBrowser.RootFolder = $RootFolder
            $FolderBrowser.ShowNewFolderButton = $False
            [void]$FolderBrowser.ShowDialog()
            if (!$FolderBrowser.SelectedPath){
                Write-Host "Cancelling installation!" -ForegroundColor Red
                return
            } else{
                
            }
        }
    }
}