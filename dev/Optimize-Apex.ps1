function Optimize-Apex {
    [alias('optal')]
    param(

        [ValidateScript({
            Test-Path $_ -Type Leaf
            (Get-Item $_).Name -eq 'r5apex.exe'
            (Get-Item $_).FullName -Like "*\Apex Legends\r5apex.exe"
        })]
        [String]$r5apexpath
    )

    $Preset = @{
        'setting.r_lod_switch_scale' = 0.05
        cl_particle_fallback_base = 4
        cl_particle_fallback_multiplier = 1
        mat_picmic = 3
        stream_memory = 200000
        
    }

### Launch Opts
$MaxHz =  (Get-CimInstance Win32_VideoController).MaxRefreshRate
$Opts = "-high -dev -forcenovsync -fullscreen -preload +mat_compressedtextures 1 +cl_ragdoll_collide 0 -threads 6 +cl_showfps 1 -console +fps_max $MaxHz"
"The following launch options have been copied to your clipboard:"
$Opts
Set-Clipboard $Opts

### Finding r5
$Shortcut = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse | Where-Object Name -eq "Apex Legends.lnk"
if (!$Shortcut){
    return "Could not find shortcut to Apex Legends in start menu, exitting.."
}
Set-CompatibilitySettings $Shortcut -DisableFullScreenOptimizations
$r5apex = Get-ShortcutTarget -ShortcutPath $Shortcut

function ConvertFrom-ApexConfig {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Config
    )
    $Original = @{}
    ForEach($Line in $Config){
        $Line = $Line -Replace '"',''
        $Key, $Value = $Line.Split(' ')
        if ($Value -is [Array]){
            $Value = $Value[0]
        }
        if (!$Original.$Key){
            $Original += @{$Key = $Value}
        }
    }
    return $Original
}

ConvertTo-ApexConfig ($Top,$Config){
    $Content = @"
$(($Top | Where-Object {$_ -NotIn '',$null}) -join [System.Environment]::NewLine)
"@
    ForEach($Setting in $Config){
        $Content += "$($Setting.Key) `"$($Setting.Value)`"" + [System.Environment]::NewLine
    }
}

### Parsing config
$autoexec = Join-Path (Split-Path $r5apex -Parent) "cfg\autoexec.cfg"
if (Test-Path $autoexec){
    $Config = Get-Content $autoexec | Where-Object {[Regex]::Matches($_,'"').Count -eq 2} # Filter there are two quotes per the line
    $Top = Get-Content $autoexec | Where-Object {[Regex]::Matches($_,'"').Count -ne 2} # Filter the rest (binds ect..)
    $Config = $Config | ConvertFrom-ApexConfig
}else{
    $Config = @{}
    $Top = @{}
}

$Profile = Get-Content "$HOME\*\Respawn\Apex\profile\profile.cfg" | ConvertFrom-ApexConfig
$Original = @{}
ForEach($Line in $Profile){
    $Line = $Line.Replace('"','')
    $Key, $Value = $Line.Split(' ')
    if (!$Original.$Key){
        $Original += @{$Key = [float]$Value}
    }
}
$Profile = $Original

}