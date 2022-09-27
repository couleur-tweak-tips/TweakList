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
        [Array]$LazyChunkLoadSpeed,


        [ValidateSet(
            'Performance',
            'NoCosmetics',
            'MinimalViewBobbing',
            'No16xSaturationOverlay',
            'HideToggleSprint'
            )]
        [Array]$Settings
    )

    if ('Performance' -in $Settings){
        Merge-Hashtables -Original $general $Presets.Performance.general
        Merge-Hashtables -Original $performance $Presets.Performance.performance
        Write-Diff -Message "notifications from LC friends getting on (causes massive FPS drop)"
        Write-Diff -Positivity $True -Message "lazy chunk loading at speed $LCLevel"
        Write-Diff -Message "ground arrows"
        Write-Diff -Message "player/mob skulls"
        Write-Diff -Message "foliage (normal/tall grass)"
    }
    if ('MinimalViewBobbing' -in $Settings){
        Merge-Hashtables -Original $general -Patch $Presets.MinimalViewBobbing.general
        Write-Diff -Positivity $True -Message "minimal view bobbing"
    }
    if ('HideToggleSprint' -in $Settings){
        Merge-Hashtables -Original $mods -Patch $Presets.HideToggleSprint.mods
        Write-Diff -Positivity $False -Term "Hid" -Message "ToggleSprint HUD"
    }
    if ('ToggleSneak' -in $Settings){
        Merge-Hashtables -Original $mods $Presets.ToggleSneak.mods
        Write-Diff -Positivity $True -Message "ToggleSneak"
    }
    if ('DisableUHCMods' -in $Settings){
        Merge-Hashtables -Original $mods -Patch $Presets.DisableUHCMods.mods
        Write-Diff -Positivity $False -Term "Disabled" -Message "Waypoints mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "DirectionHUD mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "Coordinates mod"
        Write-Diff -Positivity $False -Term "Disabled" -Message "ArmorStatus mod"
    }
    if ('FullBright' -in $Settings){
        Merge-Hashtables -Original $mods -Patch $Presets.FullBright.mods
        Write-Diff -Term "Added" -Positivity $true -Message "Fullbright (disable shaders before restarting)"
    }

    if (!$LazyChunkLoadSpeed -and ('Performance' -in $Settings)){$LazyChunkLoadSpeed = 'low'}

    $Manager = Get-Content "$LCDirectory\settings\game\profile_manager.json" -ErrorAction Stop | ConvertFrom-Json
    
    $Profiles = @{}
    ForEach($Profile in $Manager){
        $Profiles += @{ "$($Profile.DisplayName) ($($Profile.Name))" = $Profile}
    }

    while ($Selection -in $Manager.name,$Manager.DisplayName){
        Write-Host "Select a profile:"
        $Selection = Menu @([Array[]]$Profiles.Keys + 'Create a new profile')
        if ($Selection -in $Manager.name,$Manager.DisplayName){
            if ($VerbosePreference -eq 'Continue'){
                Write-Host "Manager:`n`n" -ForegroundColor Red
                Write-Host ($Manager | ConvertTo-Json)
            }
            "A profile with the same name already exists!"
        }
    }
    if ($Selection -eq 'Create a new profile'){
        
        $ProfileName = Read-Host "Enter a name for the new profile"
        New-Item -ItemType Directory -Path "$LCDirectory\settings\game\$ProfileName" -ErrorAction Stop | Out-Null
        Push-Location "$LCDirectory\settings\game\$ProfileName"
        ('general.json', 'mods.json', 'performance.json') | ForEach-Object {
            if (-Not(Test-Path ./$_)){Add-Content ./$_ -Value '{}'} # Empty json file 
        }
        Pop-Location
        $Manager += [PSCustomObject]@{

            name = $ProfileName
            displayName = $ProfileName
            active = $False
            iconName = 'crossed-swords'
            server = ''
        }
        $Selection = $Manager # Overwriting the string "Create a new profile" with the fresh one
        Set-Content -Path "$LCDirectory\settings\game\profile_manager.json" -Value ($Manager | ConvertTo-Json -Depth 99)
    }

    $ProfileDir = "$LCDirectory\settings\game\$($Selection.name)"

    ForEach($file in 'general','mods','performance'){ # Assigns $general, $mods and $performance
        Set-Variable -Name $file -Value (Get-Content "$ProfileDir\$file.json" -ErrorAction Stop | ConvertFrom-Json)
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
        Performance = @{
            general = @{
                friend_online_status_bl	= $false
            }
            performance = @{
                lazy_chunk_loading	= $LCLlevel
                ground_arrows_bl    = $false
                stuck_arrows_bl     = $false
                hide_skulls_bl      = $true
                hide_foliage_bl     = $true
            }
        }
        MinimalViewBobbing = @{
            general = @{
                minimal_viewbobbing_bl = $true
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
        FullBright = @{
            mods = @{
                lighting =@{
                    lighting_enabled_bl = $true
                    options = @{
                        full_bright_bl	= $true
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
        ToggleSneak = @{
            mods = @{
                toggleSneak = @{
                    options = @{
                        toggle_sneak_bl = $true
                    }
                }
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
    }
    if ($PSVersionTable.$PSVersionTable.$Major -eq 5){
        $LCProc = Get-Process -Name java? | Where-Object MainWindowTitle -Like "Lunar Client (*/*)"
        if ($LCProc){
            "Would you like to restart Lunar Client? [Y/N]"
            if ((Set-Choice "YN") -eq 'Y'){
                $mv = "$LCDirectory\offline\multiver"
                if(Test-Path $mv){$jrewd = $mv}
                else{
                    
                }
                $CommandLine =  (Get-WmiObject win32_process -filter "ProcessID='$($LCProc.Id)'").CommandLine
                Stop-Process $LCProc -Force -ErrorAction Stop
                Push-Location "$LCDirectory\offline\multiver"
                & $CommandLine
                Pop-Location
            }

        }
    }
}