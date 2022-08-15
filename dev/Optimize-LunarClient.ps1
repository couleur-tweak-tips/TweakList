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

    if (!$LazyChunkLoadSpeed -and ('Performance' -in $Settings)){$LazyChunkLoadSpeed = 'low'}

    $Manager = Get-Content "$LCDirectory\settings\game\profile_manager.json" -ErrorAction Stop | ConvertFrom-Json
    
    $Profiles = @{}
    ForEach($Profile in $Manager){$Profiles += @{ "$($Profile.DisplayName) ($($Profile.Name))" = $Profile}}

    "Select a profile:"
    $Selection = Menu @([Array[]]$Profiles.Keys + 'Create a new profile')
    if ($Selection -eq 'Create a new profile'){
        $ProfileName = Read-Host "Enter a name for the new profile:"
        New-Item -ItemType Directory -Path "$LCDirectory\settings\game\$ProfileName" -ErrorAction Stop | Out-Null
        Push-Location "$LCDirectory\settings\game\$ProfileName"
        ('general.json', 'mods.json', 'performance.json') % {
            if (-Not(Test-Path ./$_)){Add-Content ./$_ -Value '{}'}
        }
        Pop-Location
        $Manager = Get-Content "$LCDirectory\settings\game\profile_manager.json" | ConvertFrom-Json
        $Manager += [PSCustomObject]@{
            name = $ProfileName
            displayName = $ProfileName
            active = $False
            iconName = 'crossed-swords'
            server = ''
        }
        Set-Content -Path "$LCDirectory\settings\game\profile_manager.json" -Value ($Manager | ConvertTo-Json -Depth 99)
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
        Peformance = @{
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
                        #--HideToggleSprint
                        #showHudText_bl:	false
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
}