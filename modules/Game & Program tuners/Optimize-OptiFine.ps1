function Optimize-OptiFine {
    [alias('optof')]
    param(
        [ValidateSet('Smart','Lowest')]
        [Parameter(Mandatory)]
        $Preset,
        [String]$CustomDirectory,
        [Switch]$MultiMC,
        [Switch]$PolyMC,
        [Switch]$GDLauncher
    )

if (!$CustomDirectory){$CustomDirectory = Join-path $env:APPDATA '.minecraft'}
elseif($MultiMC){
    $CustomDirectory = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse | Where-Object Name -Like "MultiMC.lnk"
    $CustomDirectory = Get-ShortcutPath $CustomDirectory
    $CustomDirectory = Join-Path (Split-Path $CustomDirectory) instances
    "Please select a MultiMC instance"
    $CustomDirectory = menu (Get-ChildItem $CustomDirectory).Name
}elseif($PolyMC){
    $CustomDirectory = Get-ChildItem "$envAppData\PolyMC\instances"
    "Please select a PolyMC instance"
    $CustomDirectory = $CustomDirectory.Name
}elseif($GDLauncher){
    $CustomDirectory = Get-ChildItem "$envAppData\gdlauncher_next\instances"
    "Please select a GDLauncher instance"
    $CustomDirectory = $CustomDirectory.Name

}

$Presets = @{

    Smart = @{
        options = @{
            renderDistance=5
            mipmapLevels=4
            ofAoLevel=1.0
        }
        optionsof = @{
            ofMipmapType=3
            ofCustomSky=$true
        }
    }

    Lowest = @{
        options = @{
            gamma=1000000 # I've never tried anything else and this always worked
            renderDistance=2
            particles=2
            fboEnable=$true
            useVbo=$true
            showInventoryAchievementHint=$false
        }
        optionsof = @{
            ofDynamicLights=3
            ofChunkUpdates=1
            ofAoLevel=0.0 # Smooth lighting
            ofOcclusionFancy=$false
            ofSmoothWorld=$true
            ofClouds=3
            ofTrees=1
            ofDroppedItems=0
            ofRain=3
            ofAnimatedWater=2
            ofAnimatedLava=2
            ofAnimatedFire=$true
            ofAnimatedPortal=$false
            ofAnimatedRedstone=$false
            ofAnimatedExplosion=$false
            ofAnimatedFlame=$true
            ofAnimatedSmoke=$false
            ofVoidParticles=$false
            ofWaterParticles=$false
            ofPortalParticles=$false
            ofPotionParticles=$false
            ofFireworkParticles=$false
            ofDrippingWaterLava=$false
            ofAnimatedTerrain=$false
            ofAnimatedTextures=$false
            ofRainSplash=$false
            ofSky=$false
            ofStars=$false
            ofSunMoon=$false
            ofVignette=1
            ofCustomSky=$false
            ofShowCapes=$false
            ofFastMath=$true
            ofSmoothFps=$false
            ofTranslucentBlocks=1
        }
    }
}
$Global = @{
    optionsof = @{
        ofFastRender=$true
        ofClouds=3
        ofAfLevel=1 # Anisotropic filtering
        ofAaLevel=0 # Anti-aliasing
        ofRainSplash=$false
    }
    options = @{
        showInventoryAchievementHint=$false
        maxFps=260
        renderClouds=$false
        useVbo=$true
    }
}
$Presets.$Preset = Merge-Hashtables $Presets.$Preset $Global

function ConvertTo-MCSetting ($table){

    $file = @()
    ForEach($setting in $table.keys){
        $file += [String]$($setting + ':' + ($table.$setting)) -replace'True','true' -replace 'False','false'
    }
    return $file
}

foreach ($file in 'options','optionsof'){

    $Hash = (Get-Content "$CustomDirectory\$file.txt") -Replace ':','=' | ConvertFrom-StringData
    $Hash = Merge-Hashtables -Original $Hash -Patch $Presets.$Preset.$file
    Set-Content "$CustomDirectory\$file.txt" -Value (ConvertTo-MCSetting $Hash) -Force
}
$Hash = (Get-Content "$CustomDirectory\optionsLC.txt") -Replace ',"maxFps":"260"','' | ConvertFrom-Json
$Hash = Merge-Hashtables -Original $Hash -Patch $Presets.$Preset.optionsof
$Hash = Merge-Hashtables -Original $Hash -Patch $Presets.$Preset.options
$Hash.maxFPS = 260
Set-Content "$CustomDirectory\optionsLC.txt" -Value (ConvertTo-Json $Hash) -Force

}