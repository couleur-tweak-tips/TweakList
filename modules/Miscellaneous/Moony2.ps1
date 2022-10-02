function Moony2 {
    param(
        [Switch]$NoIntro,
        [Int]$McProcessID
    )
    $LaunchParameters = @{} # Fresh hashtable that will be splat with Start-Process

    if (!$NoIntro){
    Write-Host @'
If you're used to the original Moony, this works a little differently,

What you just runned lets you create a batchfile from your current running game
that you can launch via a single click or even faster: via Run (Windows +R)

Please launch your Minecraft (any client/version) and press ENTER on your keyboard
once you're ready for it to create the batchfile
'@
    Pause
    }

    # java? is regex for either java or javaw
    if (-Not(Get-Process java?)){
        Write-Host "There was no processes with the name java or javaw"
        pause
        Moony -NoIntro
        return
    }else{
        $ProcList = Get-Process -Name java?
        if ($ProcList[1]){ # If $Procs isn't the only running java process
                $Selected = Menu $ProcList.MainWindowTitle
                $Proc = Get-Process | Where-Object {$_.MainWindowTitle -eq ($Selected)} # Crappy passthru
                if ($Proc[1]){ # unlikely but w/e gotta handle it
                    Write-Host "Sorry my code is bad and you have multiple processes with the name $($Proc.MainWindowTitle), GG!"
                }
        }else{$Proc = $ProcList} # lmk if theres a smarter way
    }
    $WinProcess = Get-CimInstance -ClassName Win32_Process | Where-Object ProcessId -eq $Proc.Id
    $JRE = $WinProcess.ExecutablePath
    $Arguments = $WinProcess.CommandLine.Replace($WinProcess.ExecutablePath,'')
    if (Test-Path "$HOME\.lunarclient\offline\multiver"){
        $WorkingDirectory = "$HOME\.lunarclient\offline\multiver"

    }else{
            # This cumbersome parse has been split in 3 lines, it just gets the right version from the args
        $PlayedVersion = $Arguments.split(' ') |
        Where-Object {$PSItem -Like "1.*"} |
        Where-Object {$PSITem -NotLike "1.*.*"} |
        Select-Object -Last 1
        $WorkingDirectory = "$HOME\.lunarclient\offline\$PlayedVersion"
    }
    if ($Arguments -NotLike "* -server *"){
        Write-Host @"
Would you like this script to join a specific server right after it launches?

If so, type the IP, otherwise just leave it blank and press ENTER
"@  
        $ServerIP = Read-Host "Server IP"
        if ($ServerIP -NotIn '',$null){
            $Arguments += " -server $ServerIP"
        }
    }

    $InstanceName = Read-Host "Give a name to your Lunar Client instance, I recommend making it short without spaces"
    if ($InstanceName -Like "* *"){
        $InstanceName = Read-Host "Since there's a space in your name, you won't be able to call it from Run (Windows+R), type it again if you are sure"
    }

    Set-Content "$env:LOCALAPPDATA\Microsoft\WindowsApps\$InstanceName.cmd" @"
@echo off
cd /D "$WorkingDirectory"
start $JRE $Arguments
if %ERRORLEVEL% == 0 (exit) else (pause)
"@
    Write-Host "Your $InstanceName instance should be good to go, try typing it's name in the Run window (Windows+R)" -ForegroundColor Green
    return

}