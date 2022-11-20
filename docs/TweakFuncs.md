# TweakFuncs
Each file in [/modules/](https://github.com/couleur-tweak-tips/TweakList/tree/master/modules) and [/helpers/](https://github.com/couleur-tweak-tips/TweakList/tree/master/helpers) contains a function that has the same name,
This file shows you a list of modules and how to use each of them.
At each commit, [GitHub Actions](https://github.com/couleur-tweak-tips/TweakList/actions) compiles them to a [single file](https://github.com/couleur-tweak-tips/TweakList/blob/master/Master.ps1),
which you can run to declare all of them by simply typing `iex(irm tl.ctt.cx)` in PowerShell.

## Import-Sophia

Parses farag's [Sophia Script](https://github.com/farag2/Sophia-Script-for-Windows) and imports all functions as a temporary module

#### CB-CleanTaskbar
This is a Combo function, which imports the Sophia Script's functions (via `Import-Sophia`/`ipso`) and runs the following:
```PowerShell
CortanaButton -Hide
PeopleTaskbar -Hide
TaskBarSearch -Hide
TaskViewButton -Hide
UnpinTaskbarShortcuts Edge, Store, Mail
```
Restarting the explorer is needed for a few of them to refresh.

## Get
This lets you easily install programs and some of my scripts in a very short command that allows a lot of aliases

```ps
Get DisplayDriverUninstaller 7-Zip Smoothie
# Will do the same thing as:
g ddu 7z sm
```

## Launch

This lets you download some "throw-away" [programs](https://github.com/couleur-tweak-tips/TweakList/blob/master/modules/Installers/Launch.ps1) to TEMP, it returns the path of the main binary

- DisplayDriverUninstaller
- NVCleanstall
- NvidiaProfileInspector
- MSIUtilityV3
- Rufus
- AutoRuns
- Procmon
- CustomResolutionUtility
- NotepadReplacer
- privacy.sexy
- ReShade

(List may be out of date)


You can pair this with PowerShell's `&` operator:

```PowerShell
iex(irm tl.ctt.cx);
& (Launch DisplayDriverUninstaller)
```
It has tab completion and can loop over multiple apps (e.g `Launch DisplayDriverUninstaller, privacy.sexy, Rufus`)

## Get-ScoopApp
Used by `Get`, it installs a specific app using the [Scoop](https://scoop.sh) package manager, if it fails to find it in your available [Buckets](https://github.com/ScoopInstaller/Scoop#known-application-buckets) it look in other known buckets, as well as [mine](https://github.com/couleur-tweak-tips/utils/tree/main/bucket). You can also specify a bucket before the name of the app (e.g `extras/firefox`, `utils/smoothie`) and it will get Git/bucket if needed.
```ps
# Will do same thing as 'Get DisplayDriverUninstaller'
Get-ScoopApp extras/ddu
```



## Get-FunctionContent
Simply returns the content of a function you provide

If you're auditing or snooping at what TweakList is capable
this is a good way to lurk around
```PowerShell
Get-FunctionContent Get-ScoopApp
# or it's alias:
gfc Get-ScoopApp
```

You can also pipe what it returns to your clipboard (to paste it in your IDE)
```PowerShell
Get-FunctionContent Merge-HashTables | Set-Clipboard
```
You can also use `bat` to have vim-key navigation and syntax highlighting
```PowerShell
gfc Launch | bat -l PowerShell
```

## Optimize-OBS

This will find your OBS installation, ask you which profile to tune, and adjust the settings that matter for performance


```PowerShell
Optimize-OBS -Encoder NVENC -OBS64Path "D:\Scoop\OBS\bin\obs64.exe"
```
Available encoders are NVENC (for NVIDIA GPUs), AMF (for AMD GPUs), QuickSync (for intel iGPUs) and x264 (CPU).

## Optimize-OptiFine

Same process as OBS, if you're not using .minecraft in the APPDATA, indicate it with the GameDir `-CustomDirectory`.

```PowerShell
Optimize-OptiFine -Preset Smart
```
There is also the "Lowest" preset which turns every setting down (prepare for a very ugly game).

## Optimize-LunarClient

Specify which specific tweak you'd like applying on one (or a new) LunarClient Profile
- **Performance**: Turn off performance-hungry settings
- **NoCosmetics**: Disable all emotes, cosmetics, wings, hats..
- **MinimalViewBobbing**: Keep item movement but disable walk bobbing
- **No16xSaturationOverlay**: Remove the yellow 16x hunger bar overlay
- **HideToggleSprint**: Hides the ToggleSprint status from HUD
- **ToggleSneak**: Turns on ToggleSneak
- **DisableUHCMods**: Disables ArmorHUD, DirectionHUD and Coordinates mods
- **FullBright**: literally night vision


## Add-ContextMenu and Remove-ContextMenu
Remember that list of actions you can do when right-clicking a file/folder? The more programs you install, the more crowded it gets, Windows also has it's fair share of very specific actions no one really cares about

#### Remove-ContextMenu can remove the following:
* PinToQuickAccess
* RestorePreviousVersions
* Print
* GiveAccessTo
* EditWithPaint3D
* IncludeInLibrary
* AddToWindowsMediaPlayerList
* CastToDevice
* EditWithPaint3D
* EditWithPhotos
* Share
* TakeOwnerShip
* 7Zip
* WinRAR
* Notepad++
* OpenWithOnBatchFiles
* SendTo

Be sure to take advantage of TAB completion/cycling!
```ps
Remove-ContextMenu WinRAR, Share, EditWithPaind3D
```


#### Add-ContextMenu can add the following:
* SendTo
* TakeOwnership
* OpenWithOnBatchFiles

It works the same way as ``Remove-ContextMenu``

## RemovePackBangs

This simply removes exclamation points and spaces from the start of your resourcepack's filenames

It defaults to the default /.minecraft/resourcepacks (override it with `-PackFolderPath`), it does not check recursively for obvious reasons
turns
```PowerShell
!       §1look at me look at me I am first in your pack list!!!!!!.zip
!    §5Kool§cKirby§fKlan.zip
! Pack Special Noël !.zip
```
into
```PowerShell
§1look at me look at me I am first in your pack list!!!!!!.zip
§5Kool§cKirby§fKlan.zip
Pack Special Noël !.zip
```