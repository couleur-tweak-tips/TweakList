<p align="center">
👋 <strong>Contributors:</strong> if you'd like to contribute, feel free to <a href="https://github.com/couleur-tweak-tips/TweakList/issues/new/choose">make an issue </a> to suggest a relevant tweak
</p>

</br>
</br>
</br>

<p align="center">
    <img align=center src="https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg?sanitize=true" alt="PS7 logo" width="75" />  </br>
    <strong>TweakList</strong> </br>
    </br>
    Make your very own tweaking/debloating script, with one line per tweak   </br>
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
    <a href="https://github.com/couleur-tweak-tips/TweakList">
        <img src="https://img.shields.io/github/repo-size/couleur-tweak-tips/TweakList.svg" alt="Repository size" />
    </a>
    <a href="https://discord.com/invite/aPVMJy78Pa">
        <img src="https://img.shields.io/badge/chat-on%20discord-7289DA.svg" alt="Discord Chat" />
    </a>
    <a href="https://github.com/couleur-tweak-tips/TweakList/blob/master/LICENSE">
        <img src="https://img.shields.io/github/license/couleur-tweak-tips/TweakList.svg" alt="License" />
    </a>

</p>
</br>

[logo]: https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg?sanitize=true

TweakList is a PowerShell module aiming to regroup every impactful tweaks for fine tuning, stripping and optimizing Windows, each tweaks has it's own file **and can be put together as a "[TweakScript](https://gist.github.com/couleurm/68d272edc5fb930c31b96b667813e373 "TweakList example")"**

</br>

It aims to make common tuning easy, some stuff like:

* Common settings everyone ticks anyways
* Scripts to automatically find and tune game settings (e.g [Apex Legends](https://github.com/couleur-tweak-tips/utils/tree/main/Patchers/Apex%20Settings%20Patcher), will have something for Minecraft soon)
* Installation of programs using [scoop](http://scoop.sh), an UAC-less command line package manager for Windows
* Anything that can be automated/assisted via the Regedit/PowerShell/GPO/Batch

---


## 📝Here's a list of all the automatable tweaks I know of  

- Tune almost every Windows settings with a slightly modified functions from Sophia Script
- Minecraft: Parse and lower OptiFine / Lunar Client settings
- [Apex Settings Patcher](https://github.com/couleur-tweak-tips/utils/tree/main/Patchers/Apex%20Settings%20Patcher)
- Module for adding prioritized processes via the registry (if that even impacts performance)
- Tune Xbox Game Mode/Bar/DVR & Hardware accelerated GPU scheduling
- Rewrite [nvidia-updater](https://github.com/lord-carlos/nvidia-update/blob/master/nvidia.ps1) ft. NVCleanstall
- Warn user is bloat is running (Synapse, iCue, OneDrive), use [autorunsc](https://docs.microsoft.com/en-us/sysinternals/downloads/autoruns#autorunsc-usage) to parse every programs that run at startup

💭 *(This list will get longer as times goes on, this is what I remembered from the top of my head)*

## I've borrowed some stuff (with permission), from these scripts/lists:

* [farag2](https://i.imgur.com/Vf1pthm.png)'s [Sophia Script](https://github.com/farag2/Sophia-Script-for-Windows), it contains 150+ functions for automating Windows' settings just right (perfect when you just installed Windows)
* [Zusier](https://i.imgur.com/hAL2wGf.png)'s [optimization batch](https://github.com/Zusier/Zusiers-optimization-Batch)
* [Melody](https://i.imgur.com/6nZSqh3.png)'s [Basic Tweaks list](https://sites.google.com/view/melodystweaks/basictweaks)
* [Major Geeks](https://i.imgur.com/fKbpDnl.png)' [Windows Registry Tweaks](https://www.majorgeeks.com/files/details/majorgeeks_registry_tweaks.html), similar to Sophia Script, it also has a lot of .REGs to debloat the context menu (file right click menu)

