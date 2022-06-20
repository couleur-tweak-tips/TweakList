function Invoke-SmoothiePost {
    param(
        [String]
        [ValidateScript({
            Test-Path -Path (Get-Item $_) -PathType Container -ErrorAction Stop
        })]
        $CustomDir
    )
    # DIR is the variable used by Scoop, hence why I'm using a separate name
    if ($CustomDir -and !$DIR){
        if (!(Test-Path "$CustomDir\Smoothie") -And !(Test-Path "$CustomDir\VapourSynth")){
            Write-Host "The folder you gave needs to contain the folders 'Smoothie' and 'VapourSynth', try the right path"
        }else{
            $DIR = (Get-Item $CustomDir).FullName
        }
    }
    if (!$DIR){return "This script is suppose to be ran by Scoop after it's intallation, not manually"}

    $rc = (Get-Content "$DIR\Smoothie\settings\recipe.yaml" -ErrorAction Stop) -replace ('H264 CPU',(Get-EncodingArgs -EzEncArgs))

    if ($valid_args -like "H* CPU"){$rc = $rc -replace ('gpu: true','gpu: false')}

    Set-Content "$DIR\Smoothie\settings\recipe.ini" -Value $rc

    if (Get-Command wt.exe -Ea Ignore){$term = Get-Path wt.exe}
    else{$term = Get-Path cmd.exe}

    Get Scoop

    $SendTo = [System.Environment]::GetFolderPath('SendTo')
    $Scoop = Get-Command Scoop | Split-Path | Split-Path
    $SA = [System.IO.Path]::Combine([Environment]::GetFolderPath('StartMenu'), 'Programs', 'Scoop Apps')

    if (-Not(Test-Path $SA)){ # If not using Scoop
        $SA = [System.IO.Path]::Combine([Environment]::GetFolderPath('StartMenu'), 'Programs')
    }

    Set-Content "$Scoop\shims\sm.shim" -Value @"
path = "$DIR\VapourSynth\python.exe"
args = "$DIR\Smoothie\src\main.py"
"@
    if (-Not(Test-Path "$Scoop\shims\sm.exe")){
        Copy-Item "$Scoop\shims\7z.exe" "$Scoop\shims\sm.exe"
    }


    $Parameters = @{
        Overwrite = $True
        LnkPath = "$Scoop\shims\rc.lnk"
        TargetPath = "$DIR\Smoothie\settings\recipe.yaml"
    }
    New-Shortcut @Parameters


    $Parameters = @{
        Overwrite = $True
        LnkPath = "$SA\Smoothie Recipe.lnk"
        TargetPath = "$DIR\Smoothie\settings\recipe.yaml"
    }
    New-Shortcut @Parameters

    $Parameters = @{
        Overwrite = $True
        LnkPath = "$SA\Smoothie.lnk"
        TargetPath = $term
        Arguments = "`"$DIR\VapourSynth\python.exe`" `"$DIR\Smoothie\src\main.py`" -cui"
        Icon = "$DIR\Smoothie\src\sm.ico"
    }
    if ($term -like '*cmd.exe'){$Parameters.Arguments = '/c ' + $Parameters.Arguments}
    New-Shortcut @Parameters
    
    $Parameters = @{
        Overwrite = $True
        LnkPath = "$SendTo\Smoothie.lnk"
        TargetPath = $term
        Arguments = "`"$DIR\VapourSynth\python.exe`" `"$DIR\Smoothie\src\main.py`" -cui -input"
        Icon = "$DIR\Smoothie\src\sm.ico"

    }
    if ($term -like '*cmd.exe'){$Parameters.Arguments = '/c ' + $Parameters.Arguments}
    New-Shortcut @Parameters

}
