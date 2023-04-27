function Optimize-Bedrock {
    [CmdletBinding()]
    param(


        [ValidateScript({
                Test-Path $_ -PathType Leaf
            })]
        [String]$options = "$env:localappdata\Packages\Microsoft.MinecraftUWP_8wekyb3d8bbwe\LocalState\games\com.mojang\minecraftpe\options.txt",


        [ValidateSet('Low', 'High', 'ashanksupercool')]
        $Preset = "High",

        $Presets = @{

            High     = @{
                options = @{
                    gfx_viewdistance           = 256
                    gfx_particleviewdistance   = 1
                    gfx_viewbobbing            = 1
                    gfx_fancygraphics          = 1
                    gfx_transparentleaves      = 1
                    gfx_smoothlighting         = 1
                    gfx_fancyskies             = 1
                    gfx_msaa                   = 4
                    gfx_texel_aa_2             = 0
                    gfx_multithreaded_renderer = 1
                    gfx_vsync                  = 0
                }
            } 
        
            Low      = @{
                options = @{
                    gfx_viewdistance           = 160
                    gfx_particleviewdistance   = 0
                    gfx_viewbobbing            = 0
                    gfx_fancygraphics          = 0
                    gfx_transparentleaves      = 0
                    gfx_smoothlighting         = 0
                    gfx_fancyskies             = 0
                    gfx_msaa                   = 1
                    gfx_texel_aa_2             = 0
                    gfx_multithreaded_renderer = 1
                    gfx_vsync                  = 0
                }
            }
            ashanksupercool = @{
                options = @{
                    gfx_viewdistance                                 = 256
                    gfx_particleviewdistance                         = 1
                    gfx_viewbobbing                                  = 1
                    gfx_fancygraphics                                = 0
                    gfx_transparentleaves                            = 1
                    gfx_vr_transparentleaves                         = 0
                    gfx_smoothlighting                               = 1
                    gfx_vr_smoothlighting                            = 0
                    gfx_fancyskies                                   = 0
                    gfx_field_of_view                                = 81.2
                    gfx_msaa                                         = 1
                    gfx_gamma                                        = 1
                    gfx_multithreaded_renderer                       = 1
                    gfx_vsync                                        = 0
                    dev_file_watcher                                 = 1
                    audio_music                                      = 0
                    gfx_hidepaperdoll                                = 1
                    dev_enable_texture_hot_reloader                  = 1
                    do_not_show_multiplayer_online_safety_warning    = 1
                    only_show_trusted_skins                          = 0
                    camera_shake                                     = 0
                    gfx_resizableui                                  = 0
                    gfx_hotbarScale                                  = 1
                    'keyboard_type_0_key.pickItem'                   = 75
                    'keyboard_type_0_key.hotbar.1'                   = 49
                    'keyboard_type_0_key.hotbar.2'                   = 50
                    'keyboard_type_0_key.hotbar.3'                   = 51
                    'keyboard_type_0_key.hotbar.4'                   = 52
                    'keyboard_type_0_key.hotbar.5'                   = 82
                    'keyboard_type_0_key.hotbar.6'                   = 70
                    'keyboard_type_0_key.hotbar.7'                   = 86
                    'keyboard_type_0_key.hotbar.8'                   = 90
                    'keyboard_type_0_key.hotbar.9'                   = '- 97'
                    'keyboard_type_0_key.inventory'                  = 69
                    'keyboard_type_0_key.togglePerspective'          = 53
                    'keyboard_type_0_key.jump'                       = 32
                    'keyboard_type_0_key.sneak'                      = 16
                    'keyboard_type_0_key.sprint'                     = 17
                    'keyboard_type_0_key.left'                       = 65
                    'keyboard_type_0_key.right'                      = 68
                    'keyboard_type_0_key.back'                       = 83
                    'keyboard_type_0_key.forward'                    = 87
                    'keyboard_type_0_key.mobEffects'                 = 88
                    'keyboard_type_0_key.chat'                       = 13
                    'keyboard_type_0_key.emote'                      = 0


                }
            }
        }
    )

    Write-Host "Optimize Minecraft bedrock with $Preset"

    $optionsTable = (Get-Content $options) -Replace ':', '=' | ConvertFrom-StringData
    Write-Verbose ($optionsTable | ConvertTo-Json -Depth 3)
    $optionsTable = Merge-Hashtables -Original $optionsTable -Patch $Presets.$Preset.options
    Write-Verbose ($optionsTable | ConvertTo-Json -Depth 3)
    Set-Content $options -Value (ConvertTo-MCSetting $optionsTable) -Force
}
