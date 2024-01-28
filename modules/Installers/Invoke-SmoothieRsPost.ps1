# This does not install Smoothie, it simply creates shortcuts in the start menu, Send To and configures the recipe
function Invoke-SmoothieRsPost {
    param(
        
        [ValidateScript({
                Test-Path -Path (Get-Item $_) -PathType Container -ErrorAction Stop
            })]
        [String]$DIR,
        [Switch]$Scoop,
        [Switch]$Uninstall
    )

    $ErrorActionPreference = 'Stop'

    <#
        .SYNOPSIS
        Merges recipes

        .NOTES
        It returns void, it just applies all patches on what was passed to -Original

        .NOTES
        Limitations:
        - It cannot remove keys from $OG, most it can do is Patch containing a same key that is $null

        .PARAMETER Original
        The original hashtable which will get modified
        .PARAMETER Patches
        Recursively merge with $Original
    #>
    function Merge-Recipe {
        [CmdletBinding()]
        param (
            $Original,
            $Patch
        )
        foreach ($category in $Patch.GetEnumerator()) {
            
            $key, $patch = $category.name, $category.value

            if ($Original.Contains($key) -and ($Original[$key] -is [Collections.Specialized.OrderedDictionary] -and $Patch -is [Collections.Specialized.OrderedDictionary])) {
                Merge-Recipe -Original $Original[$key] -Patch $Patch
            }
            else {
                $Original[$key] = $Patch
            }
        }
    }
    
    $SendTo = [System.Environment]::GetFolderPath('SendTo')
    $Start = [System.IO.Path]::Combine([Environment]::GetFolderPath('StartMenu'), 'Programs')

    if (!$SendTo -or !(Test-Path $SendTo)) {
        return "FATAL: Send To folder [$SendTo] does not exist, did you/a script strip it?"
    }
    if (!$Start -or !(Test-Path $Start)) {
        return "FATAL: Start Menu folder [$Start] does not exist, did you/a script strip it?"
    }

    if ($Scoop){
        $shims = (Resolve-Path $DIR/../../../shims).Path
    }

    if ($Uninstall) {
        Remove-Item "$Sendto\Smoothie.lnk"
        Remove-Item "$SA\Smoothie.lnk"
        if ($Scoop) {
            Remove-Item "$shims\rc.lnk"
        }
        return
    }

    if ($Scoop) {
        $old_VERSIONS = Get-ChildItem $dir/.. -Directory -Exclude current, $version
        $old_DIR = switch ($old_VERSIONS.Length) {
            { $_ -in 0, $null } {}
            1 { $old_VERSIONS }
            default {
                $script:ret = ""
                $script:mostRecentDate = [datetime]::MinValue

                $old_VERSIONS | ForEach-Object {
                    $string = $_.BaseName -replace "Nightly_"
                    $datetime = [datetime]::ParseExact($string, "yyyy.MM.dd_HH-mm", [CultureInfo]::InvariantCulture)

                    if ($datetime -gt $script:mostRecentDate) {
                        $script:mostRecentDate = $datetime
                        $script:ret = $_
                    }
                }

                if ($script:mostRecentDate -eq [datetime]::MinValue) {
                    write-Warning "Failed to parse old versions:"
                    Write-Host $old_VERSIONS.FullName
                }

                $script:ret
            }
        }

        if ($old_DIR -and (Test-Path $old_DIR)) {

            [Collections.Specialized.OrderedDictionary]$old_MACROS = Get-IniContent $old_DIR/encoding_presets.ini -KeyValSeparator ':'
            [Collections.Specialized.OrderedDictionary]$new_MACROS = Get-IniContent $DIR/encoding_presets.ini -KeyValSeparator ':'
            
            Merge-Recipe $new_MACROS $old_MACROS
            $new_MACROS | Out-IniFile $DIR/encoding_presets.ini -Pretty -Force -Loose -KeyValSeparator ':'

            $old_RECIPES = Get-ChildItem $old_DIR -File -Filter *.ini | Where-Object BaseName -Notin 'defaults', 'encoding_presets'

            $old_RECIPES | ForEach-Object {
                [Collections.Specialized.OrderedDictionary]$old_RC = Get-IniContent $_.FullName -KeyValSeparator ':'
                [Collections.Specialized.OrderedDictionary]$new_RC = Get-IniContent $DIR\recipe.ini -KeyValSeparator ':'
                
                Merge-Recipe $new_RC $old_RC
                $new_RC | Out-IniFile $DIR/$($_.BaseName).ini -Pretty -Force -Loose -KeyValSeparator ':'
            }
            $old_files = Get-ChildItem $old_DIR | Where-Object Name -notin 'defaults.ini', 'encoding_presets.ini', 'jamba.vpy', 'bin', 'recipe.ini', 'launch.cmd', 'manifest.json', 'install.json'

            $old_files | ForEach-Object { Move-Item $_.FullName $DIR -Verbose }

        }
    }

    $SendTo = [System.Environment]::GetFolderPath('SendTo')
    $Start = [System.IO.Path]::Combine([Environment]::GetFolderPath('StartMenu'), 'Programs')
    . { # Shortcuts
        if (!$SendTo -or !(Test-Path $SendTo)) {
            return "FATAL: Send To folder [$SendTo] does not exist, did you/a script strip it?"
        }
        if (!$Start -or !(Test-Path $Start)) {
            return "FATAL: Start Menu folder [$Start] does not exist, did you/a script strip it?"
        }

        # %APPDATA%\Microsoft\Windows\SendTo\Smoothie.lnk
        $Parameters = @{
            Overwrite  = $True
            LnkPath    = "$SendTo\&Smoothie.lnk"
            TargetPath = "$DIR\bin\smoothie-rs.exe"
            Arguments  = "--tui -i"
        }
        New-Shortcut @Parameters

        if ($Scoop) {
            
            # %USERPROFILE%\scoop\shims\rc.lnk
            $Parameters = @{
                Overwrite  = $True
                LnkPath    = "$shims\rc.lnk"
                TargetPath = "$dir\recipe.ini"
            }
            New-Shortcut @Parameters
        }
        else {
            # %APPDATA%\Microsoft\Windows\Start Menu\Programs\Smoothie Recipe.lnk
            $Parameters = @{
                Overwrite  = $True
                LnkPath    = "$Start\Smoothie Recipe.lnk"
                TargetPath = "$DIR\recipe.ini"
            }
            # %APPDATA%\Microsoft\Windows\Start Menu\Programs\Smoothie.lnk
            New-Shortcut @Parameters
            $Parameters = @{
                Overwrite  = $True
                LnkPath    = "$Start\Smoothie.lnk"
                TargetPath = "$DIR\bin\smoothie-rs.exe"
                Arguments  = "--tui -i"
            }
            New-Shortcut @Parameters
        }
    }

}