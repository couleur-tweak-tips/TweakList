<#
    .SYNOPSIS

    Downloads and extracts (uses 7z if available) (or just clones with git, if available) the TweakList repo GitHub

    It starts by checking the commit count to see if it needs to update

#>

$FunctionTime =  [System.Diagnostics.Stopwatch]::StartNew() # Makes a variable of how much time has passed since this was declared

# Warns itself if not ran as Administrator
If (-Not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator'))
{
    Write-Host "WARNING: You are not running PowerShell as an Administrator, a lot of functions may break" -ForegroundColor DarkRed
    ''
    Start-Sleep 3
}


$org = 'couleur-tweak-tips'
$repo = 'TweakList'


$ParseTime = [System.Diagnostics.Stopwatch]::StartNew()

if (Get-Command curl.exe -Ea Ignore){ # unlike Invoke-WebRequest, curl.exe does not make a flashing blue banner

    $script:API = curl.exe -s -I -k "https://api.github.com/repos/$org/$repo/commits?per_page=1"

    $CommitCount = (($API[9] -split '&page=') -split '>;')[3]

}else{

    $script:API = (Invoke-WebRequest -Useb  "https://api.github.com/repos/$org/$repo/commits?per_page=1").RawContent

    $CommitCount = (($API -split "&page=")[2] -split '>; rel="last"')[0]

}

Write-Verbose "Parsed GitHub's API in $($ParseTime.Elapsed.Milliseconds)ms"
Remove-Variable -Name ParseTime


if ($CommitCount -in '',$null -or $CommitCount -NotIn 0..9999){
    Write-Host "Failed to parse TweakList commit count" -ForegroundColor DarkRed
    ''
    pause
    return
}

$folder = Join-Path $env:TEMP "$Repo-$CommitCount"

if (Test-Path $folder){
    Write-Host "Latest TweakList version already installed (cc @ $CommitCount)" -ForegroundColor Green

}else{

    if (Get-Command git.exe -ErrorAction Ignore){

    Write-Host 'Cloning with Git (faster)' -ForegroundColor Green

    git.exe clone https://github.com/$org/$repo.git "$Folder"

    }else{

        $URL = "https://github.com/$org/$repo/archive/refs/heads/master.zip"

        $Zip = "$env:TMP\TweakList.zip"

        Invoke-WebRequest -UseBasicParsing $URL -OutFile $Zip

        if (Get-Command 7z.exe -ErrorAction Ignore){
            7z.exe x "$Zip" -o"$folder"
        }else{

            try{
                Expand-Archive -LiteralPath $Zip -DestinationPath $Folder -Force
            }catch{

                Write-Host "Failed to extract the zip, exiting" -ForegroundColor DarkRed
                ''
                pause
                return
            }
        }
        Remove-Item $Zip -Force -ErrorAction Inquire
    }
}

$ImportTime =  [System.Diagnostics.Stopwatch]::StartNew()
Write-Host 'Importing the functions.. ' -NoNewline

Remove-Variable -Name Functions -ErrorAction Ignore # Resets this function just incase

Set-ExecutionPolicy Bypass -Scope Process -Force # Allows Import-Module to be used

$Parameters = @{
    Path = $Folder
    Recurse = $true
    Exclude = 'import.ps1'
    Include = '*.ps1'
}

Get-ChildItem @Parameters | ForEach-Object { # Gets every function

    try{
        Write-Verbose "Importing $((Get-Item $PSItem).BaseName)"
        . $(Get-Item $PSItem).FullName
    }catch{
        ''
        Write-Host "Failed to Import function $((Get-Item $PSItem).BaseName)" -ForegroundColor Red
    }

    $Functions++
}

Write-Host 'Done!' -ForegroundColor Green
Write-Verbose "Imported $Functions functions in $($ImportTime.ElapsedMilliseconds)ms, $($FunctionTime.ElapsedMilliseconds)ms in total"
