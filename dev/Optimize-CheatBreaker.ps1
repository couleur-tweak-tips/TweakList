function Optimize-CheatBreaker {
    param(
        [String]$gameDir = (if($isLinux){"$HOME\.minecraft"}else{"$env:APPDATA\.minecraft"})
    )

    $Presets = @{
        All = @{
            global = @{
                "Transparent background" = $true
                "Dark Mode" = $True
                "Customization Level" = "Advanced"
                "Container Background" = "None"
                "Show Potion info in inventory" = $false
                labels = @{

                }
            }
            profile = @{
                "Pack Tweaks" = @{
                    "Clear Glass" = "REGULAR"
                    "Transparent Inventory" = $true
                }
            }
        }
        NoCosmetics = @{
            global = @{
                "Show CheatBreaker Capes" = $False
                "Show CheatBreaker Wings" = $false
                "Show OptiFine Hats" = $false
            }
        }
        BorderlessFullscreen = @{
            global = @{
                "Borderless Fullscreen" = $true
            }
        }
        ConfirmDisconnect = @{
            global = @{
                "Disconnect Confirmation Prompt" = $true
            }
        }
        PotionEffects = @{
            state = $true
            settings = @{
                "Amplifier Exclude List" = @(12)
                "Duration Exclude List" = @(12)
                "Exclude Specific Effects" = @(12)
                "Effect Name" = $False
                "Icon" = false
            }
            info = @{
                "xTranslation" = 91
                "state" = true
                "position" = "MIDDLE_BOTTOM_RIGHT"
            }
        }
        StrongVignette = @{
            "Pack Tweaks" = @{
                state = $true
                "Vignette Minimum Opacity" = 100
                "Vignette Type" = "Amplified"
            }
        }
        FastChat = @{
            "Chat" = @{
                state = $true
                "Show Background" = "OFF"
            }
        }
        NoBossbarAndCooldowns = @{
            "Boss Bar" = @{
                state = $false
            }
            "Cooldowns" = @{
                state = $false
            }
        }
        AlwaysCritsAndSharpParticles = @{
            "Particles" = @{
                state = $true
                "Sharpness Particles" = "Always"
                "Show Active Effect Particles" = false
                "Crit Particles" = "Always"
            }
        }
        TurnOnToggleSprintHidden = @{
            "renderHUD" = false
            "state" = true
        }
        MotionBlur = @{
            "Amount" = 10
            "wasRenderHUD" = $true
            "state" = true
        }
    }


}