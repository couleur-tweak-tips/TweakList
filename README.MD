</br>

<p align="center">
    <img align=center src="https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg?sanitize=true" alt="PS7 logo" width="75" />  </br>
    <strong>TweakList</strong> </br>
    </br>
    Make your very own tweaking/debloating script, one tweak per line</br>
    <i>Tweak interpreter based in PowerShell</i></br>
    <a href="#overview">Overview</a>
    •
    <a href="https://dsc.gg/ctt">Discord Server</a>
    •
    <a href="https://github.com/couleur-tweak-tips/TweakList/tree/main/Docs">Docs</a>
</p>
<p align="center">
    <a href="https://github.com/couleur-tweak-tips/TweakList">
        <img src="https://img.shields.io/github/languages/code-size/couleur-tweak-tips/TweakList.svg" alt="Code Size" />
    </a>
    <a href="https://discord.com/invite/aPVMJy78Pa">
        <img src="https://img.shields.io/discord/774315187183288411?color=7389D8&labelColor=6A7EC2&label=Discord&logo=discord&logoColor=white alt="Discord" />
    </a>
    <a href="https://github.com/couleur-tweak-tips/TweakList/blob/master/LICENSE">
        <img src="https://img.shields.io/github/license/couleur-tweak-tips/TweakList.svg" alt="License" />
    </a>

</p>
</br>

[logo]: https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg?sanitize=true

TweakList is a PowerShell module aiming to regroup every impactful tweaks for fine tuning, stripping and optimizing Windows, each tweaks has it's own file **and can be put together as a "[TweakScript](https://gist.github.com/couleurm/68d272edc5fb930c31b96b667813e373 "TweakList example")"**

## Get started with a single command
Each function has it's [own file](https://github.com/couleur-tweak-tips/TweakList/tree/master/modules), but [CI](https://github.com/couleur-tweak-tips/TweakList/blob/master/.github/workflows/main.yml) adds up all of them at each commit to a single file ([Master.ps1](https://github.com/couleur-tweak-tips/TweakList/blob/master/Master.ps1)) which you can import with the following command:
```PowerShell
iex(irm tl.ctt.cx);
```

You can learn more about [all the things it can do](https://github.com/couleur-tweak-tips/TweakList/blob/master/Master.ps1) in [/docs/](https://github.com/couleur-tweak-tips/TweakList/tree/master/docs)
</br>

##### It can do very useful stuff like:

* [Completely automated setup and installation of Scoop and any app you wish](https://github.com/couleur-tweak-tips/TweakList/blob/master/docs/TweakFuncs.md#get)
* Set up [OBS](https://github.com/couleur-tweak-tips/TweakList/blob/master/docs/TweakFuncs.md#optimize-obs), [OptiFine](https://github.com/couleur-tweak-tips/TweakList/blob/master/docs/TweakFuncs.md#optimize-optifine) and [Voukoder](https://youtu.be/BBp2PnmRHmk) in the snap of a finger
* [Remove useless entries from the context menu (aka file/folder right click menu)](https://github.com/couleur-tweak-tips/TweakList/blob/master/modules/Remove-ContextMenu.ps1)
* [Import functions](https://github.com/couleur-tweak-tips/TweakList/blob/master/modules/Import-Sophia.ps1) from [Sophia Script](https://github.com/farag2/Sophia-Script-for-Windows)
* Easily run 


---


## 📝Tweak Functions planned:

- "Global checks" function that warns user if bloat is running (Synapse, iCue, OneDrive)
- Use and parse [autorunsc](https://docs.microsoft.com/en-us/sysinternals/downloads/autoruns#autorunsc-usage) to parse every programs that runs at startup
- Make combos that run multiple functions at once (e.g completly cleans the taskbar)
- Disabling defender / mitigations / spectre & meltdown (with warnings of course)
- Heavy stripping (with warnings of course)
- Quick ways to download & run the latest version of DDU/NVCleanstall

💭 *(This list will get longer as times goes on, this is what I remembered from the top of my head)*

## How TweakList works in the background:

- Each Tweak Function has it's own designated file, with a function declaration that has the exact same name as the file that hosts it
- At each commit, GitHub actions will add up the content of every single file into a Master script that holds the latest version of every Tweak Function
- Then people can open PowerShell and run the Master script, which will let the user be able to run every TweakList function, this can be used in a script (e.g your favorite e-sport player's tweaklist) or simply be typed from the command line

## I've borrowed some stuff (with permission), from these scripts/lists:

* [farag2](https://i.imgur.com/Vf1pthm.png)'s [Sophia Script](https://github.com/farag2/Sophia-Script-for-Windows), it contains 150+ functions for automating Windows' settings just right (perfect when you just installed Windows)
* [Zusier](https://i.imgur.com/hAL2wGf.png)'s [optimization batch](https://github.com/Zusier/Zusiers-optimization-Batch)
* [Melody](https://i.imgur.com/6nZSqh3.png)'s [Basic Tweaks list](https://sites.google.com/view/melodystweaks/basictweaks)
* [Major Geeks](https://i.imgur.com/fKbpDnl.png)' [Windows Registry Tweaks](https://www.majorgeeks.com/files/details/majorgeeks_registry_tweaks.html), similar to Sophia Script, it also has a lot of .REGs to debloat the context menu (file right click menu)

