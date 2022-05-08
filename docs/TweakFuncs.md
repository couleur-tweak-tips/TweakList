# TweakFuncs
Each file in [/modules/](https://github.com/couleur-tweak-tips/TweakList/tree/master/modules) and [/helpers/](https://github.com/couleur-tweak-tips/TweakList/tree/master/helpers) contains a function that has the same name,
This file shows you a list of modules and how to use each of them.
At each commit, [GitHub Actions](https://github.com/couleur-tweak-tips/TweakList/actions) compiles them to a [single file](https://github.com/couleur-tweak-tips/TweakList/blob/master/Master.ps1),
which you can run to declare all of them by simply typing `iex(irm tl.ctt.cx)` in PowerShell.

## Get
This lets you easily install programs and some of my scripts in a very short command that allows a lot of aliases

```ps
Get DisplayDriverUninstaller 7-Zip Smoothie
# Will do the same thing as:
g ddu 7z sm
```

## Get-ScoopApp
Used by `Get`, it installs a specific app using the [Scoop](https://scoop.sh) package manager, if it fails to find it in your available [Buckets](https://github.com/ScoopInstaller/Scoop#known-application-buckets) it look in other known buckets, as well as [mine](https://github.com/couleur-tweak-tips/utils/tree/main/bucket). You can also specify a bucket before the name of the app (e.g `extras/firefox`, `utils/smoothie`) and it will get Git/bucket if needed.
```ps
# Will do same thing as 'Get DisplayDriverUninstaller'
Get-ScoopApp extras/ddu
```



## Get-FunctionContent
Simply returns the content of a function you provide

```ps
Get-FunctionContent CB-CleanTaskbar
# or it's alias:
gfc CB-cleanTaskbar
```
<!--
## Get-NVIDIADriver and Get-AMDDriver
These two functions will install the latest driver for your GPU, with an option to extract it [using 7-Zip](https://github.com/couleur-tweak-tips/TweakList/tree/master/modules) and strip out miscellaneous components (kind of like NVCleanstall).

You can specify to extract and strip a specific driver:
```ps
Get-AMDDriver -Filepath "C:\Users\Example\Downloads\amd-software-adrenalin-edition-22.4.1-win10-win11-april5.exe"
```

There's also a few switches for Get-NVIDIADriver:
* `-Minimal` will strip the driver from miscellaneous components using 7-Zip.
* `-OpenLink` will open the download link in your default browser.
* `-GetLink` will return the download link.
* `-Studio` will install Studio drivers


-->
## Optimize-OBS

This will try find your OBS installation (unless you specify `-OBS64Path`) and adjust the settings that matter for performance

```ps
Optimize-OBS -Encoder NVENC -OBS64Path "D:\Scoop\OBS\bin\obs64.exe"
```
Available encoders are NVENC (for NVIDIA GPUs), AMF (for AMD GPUs), QuickSync (for intel iGPUs) and x264 (CPU).

## Optimize-OptiFine

Same process as OBS, if you're not using .minecraft in the APPDATA, indicate it with the parameter `-CustomDirectory`.

```ps
Optimize-OptiFine -Preset Smart
```
There is also the "Lowest" preset which turns every setting down (prepare for a very ugly game).

## CB-CleanTaskbar
This is a Combo function, which imports the Sophia Script's functions (via `Import-Sophia`/`ipso`) and runs the following:
```ps
CortanaButton -Hide
PeopleTaskbar -Hide
TaskBarSearch -Hide
TaskViewButton -Hide
UnpinTaskbarShortcuts Edge, Store, Mail
```
Restarting the explorer is needed for a few of them to refresh.

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


## Simple TweakFuncs

* ``Check-XMP`` - Parses your RAM speed to see if you need to turn on XMP
* ``Block-RazerSynapse`` - Creates an empty file at ``C:\Windows\Installer\Razer`` to prevent Razer Synapse from automatically installing every few weeks.

<!--
```ps

```