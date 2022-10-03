function Optimize-LunarClient {
    [alias('optlc')]
    param(
        [String]
        $LCDirectory = "$HOME\.lunarclient",


        [ValidateSet(
            'highest',
            'high',
            'medium',
            'low',
            'lowest',
            'off_van'
            )]
        [Array]$LazyChunkLoadSpeed = 'low',


        [ValidateSet(
            'Performance',
            'NoCosmetics',
            'MinimalViewBobbing',
            'No16xSaturationOverlay',
            'HideToggleSprint',
            'ToggleSneak',
            'DisableUHCMods',
            'FullBright',
            'CouleursPreset'
            )]
        [Array]$Settings,

        [Switch]$NoBetaWarning,
        [Switch]$KeepLCOpen,
        [Switch]$DryRun
    )
    if (!$NoBetaWarning){
        Write-Warning "This script may corrupt your Lunar Client profiles, continue at your own risk,`nyou're probably safer if you copy the folder located at $(Convert-Path $HOME\.lunarclient\settings\game)"
        pause
    }
    if (!$KeepLCOpen){
        while ((Get-Process -Name java?).MainWindowTitle -Like "Lunar Client*"){
            Write-Host "You must quit Lunar Client before running these optimizations (LC will overwrite them when it exits)" -ForegroundColor Red
            pause
        }
    }else{
        Write-Warning "You disabled the script from not running if Lunar Client is running, here be dragons!"
        Start-Sleep -Milliseconds 500
    }

    if (!$LazyChunkLoadSpeed -and ('Performance' -in $Settings)){$LazyChunkLoadSpeed = 'low'}

    $Manager = Get-Content "$LCDirectory\settings\game\profile_manager.json" -ErrorAction Stop | ConvertFrom-Json
    
    $Profiles = @{}
    ForEach($Profile in $Manager){
        $Profiles += @{ "$($Profile.DisplayName) ($($Profile.Name))" = $Profile}
    }

    Write-Host "Select a profile:"
    $Selection = Menu @([Array[]]'Create a new profile' + [Array[]]$Profiles.Keys)
    if ($Selection -in $Manager.name,$Manager.DisplayName){
        if ($VerbosePreference -eq 'Continue'){
            Write-Host "Error, Manager:`n`n" -ForegroundColor Red
            Write-Host ($Manager | ConvertTo-Json)
            return
            
        }
        return "A profile with the same name already exists!"
    }

    if ($Selection -eq 'Create a new profile'){
        
        $ProfileName = Read-Host "Enter a name for the new profile"
        New-Item -ItemType Directory -Path "$LCDirectory\settings\game\$ProfileName" -ErrorAction Stop | Out-Null
        Push-Location "$LCDirectory\settings\game\$ProfileName"
        ('general.json', 'mods.json', 'performance.json') | ForEach-Object {
            if (-Not(Test-Path ./$_)){Add-Content ./$_ -Value '{}'} # Empty json file 
        }
        Pop-Location
        $Selection = [PSCustomObject]@{

            name = $ProfileName
            displayName = $ProfileName
            active = $False
            default = $False
            iconName = 'crossed-swords'
            server = ''
        }
        $Manager += $Selection # Overwriting the string "Create a new profile" with the fresh one
        Set-Content -Path "$LCDirectory\settings\game\profile_manager.json" -Value ($Manager | ConvertTo-Json -Compress -Depth 99)
    }else{
        $Selection = $Profiles.$Selection
    }

    $ProfileDir = "$LCDirectory\settings\game\$($Selection.name)"
    ForEach($file in 'general','mods','performance'){ # Assigns $general, $mods and $performance variables
        Set-Variable -Scope Global -Name $file -Value (Get-Content "$ProfileDir\$file.json" -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
        if ($DryRun){
        Write-Host $file -ForegroundColor Red
        (Get-Variable -Name $file).Value | ConvertTo-Json
        }
    }
    
    $Presets = @{
        All = @{
            general = @{
                shift_effects_bl         = $false
                achievements_bl	         = $false
                compact_menu_bl          = $true
                modernKeybindHandling_bl = $true
                borderless_fullscreen_bl = $true
            }
            mods = @{
                chat = @{
                    options = @{
                        chat_bg_opacity_nr = "0.0"
                    }
                }
                scoreboard = @{
                    options = @{
                        numbers_bl = $true
                    }
                }
            }
        }
        CouleursPreset = @{
            mods = @{
                scoreboard = @{
                    x = 2 # Moves scoreboard 2 pixels to the right
                }
            }
        }
        Performance = @{
            general = @{
                friend_online_status_bl	= $false
            }
            performance = @{
                lazy_chunk_loading	= $LazyChunkLoadSpeed
                ground_arrows_bl    = $false
                stuck_arrows_bl     = $false
                hide_skulls_bl      = $true
                hide_foliage_bl     = $true
            }
        }
        NoCosmetics = @{
            general = @{
                renderClothCloaks_bl         = $false
                render_cosmetic_particles_bl = $false
                backpack_bl                  = $false
                dragon_wings_bl              = $false
                pet_bl                       = $false
                glasses_bl                   = $false
                bandanna_bl                  = $false
                mask_bl                      = $false
                belts_bl                     = $false
                neckwear_bl                  = $false
                bodywear_bl                  = $false
                hat_bl                       = $false
                render_emotes_bl             = $false
                render_emote_particles_bl    = $false
                cloak_bl                     = $false
                show_hat_above_helmet_bl     = $false
                show_over_chestplate_bl      = $false
                show_over_leggings_bl        = $false
                show_over_boots_bl           = $false
                scale_hat_with_skinlayer_bl  = $false
            }
        }
        MinimalViewBobbing = @{
            general = @{
                minimal_viewbobbing_bl = $true
            }
        }
        HideToggleSprint = @{
            mods = @{
                toggleSneak = @{
                     options = @{
                         showHudText_bl = $false
                     }
                }
            }
        }
        ToggleSneak = @{
            mods = @{
                toggleSneak = @{
                    options = @{
                        toggle_sneak_bl = $true
                    }
                }
            }
        }
        DisableUHCMods = @{
            mods = @{
                waypoints = @{
                    waypoints_enabled_bl = $false
                }
                directionhud = @{
	                directionhud_enabled_bl = $false
                }
                coords = @{
	                coords_enabled_bl = $false
                }                
                armorstatus = @{
	                armorstatus_enabled_bl = $false
                }
            }
        }
        FullBright = @{
            mods = @{
                lighting = @{
                    lighting_enabled_bl = $true
                    options = @{
                        full_bright_bl	= $true
                    } 
                }
            }
        }

    }
        # Whatever you do that's highly recommended :+1:
    $general = Merge-Hashtables -Original $general -Patch $Presets.All.general
    $mods = Merge-Hashtables -Original $mods -Patch $Presets.All.mods
    Write-Diff "Setting recommended settings (compact mods, fast chat).."

    if ('Performance' -in $Settings){
        $general = Merge-Hashtables -Original $general -Patch $Presets.Performance.general
        $performance = Merge-Hashtables -Original $performance -Patch $Presets.Performance.performance
        Write-Diff -Message "notifications from LC friends getting on (causes massive FPS drop)"
        Write-Diff -Positivity $True -Message "lazy chunk loading at speed $LazyChunkLoadSpeed"
        Write-Diff -Message "ground arrows"
        Write-Diff -Message "player/mob skulls"
        Write-Diff -Message "foliage (normal/tall grass)"
    }
    if ('NoCosmetics' -in $Settings){
        $general = Merge-Hashtables -Original $general -Patch $Presets.NoCosmetics.general
        ForEach($CosmeticRemoved in @(
            "cloth cloaks" 
            "cosmetic particles" 
            "backpacks" 
            "pets"
            "dragon wings"
            "bandannas"
            "masks"
            "belts"
            "neckwears"
            "bodywears"
            "hats"
            "emotes rendering"
            "emote particles rendering"
            "cloaks"
        )){
            Write-Diff -Message $CosmeticRemoved -Term "Disabled"
        }

    }
    if ('MinimalViewBobbing' -in $Settings){
        $general = Merge-Hashtables -Original $general -Patch $Presets.MinimalViewBobbing.general
        Write-Diff -Positivity $True -Message "minimal view bobbing"
    }
    if ('HideToggleSprint' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.HideToggleSprint.mods
        Write-Diff -Positivity $False -Term "Hid" -Message "ToggleSprint HUD"
    }
    if ('ToggleSneak' -in $Settings){
        $mods = Merge-Hashtables -Original $mods $Presets.ToggleSneak.mods
        Write-Diff -Positivity $True -Message "ToggleSneak"
    }
    if ('DisableUHCMods' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.DisableUHCMods.mods
        Write-Diff -Positivity $False -Term "Disabled" -Message "Waypoints mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "DirectionHUD mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "Coordinates mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "ArmorStatus mod"
    }
    if ('FullBright' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.FullBright.mods
        Write-Diff -Term "Added" -Positivity $true -Message "Fullbright (disable shaders before restarting)"
    }
    if ('CouleursPreset' -in $Settings){
        $mods = Merge-Hashtables -Original $mods -Patch $Presets.CouleursPreset.mods
    }

    ForEach($file in 'general','mods','performance'){ # Assigns $general, $mods and $performance variables
        if ($DryRun){
            Write-Host $file -ForegroundColor Red
            (Get-Variable -Name $file).Value
        }else{
            ConvertTo-Json -Depth 99 -Compress -InputObject (Get-Variable -Name $file).Value -ErrorAction Stop | Set-Content "$ProfileDir\$file.json" -ErrorAction Stop
        }
    }

}