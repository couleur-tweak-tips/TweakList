# Functions

1. All your code in your .ps1 file must be within a function declaration block (unless you have a good reason for it), doing so makes it not execute and will only be interpreted when it'll be ran by a user/other function.
2. Use a `param()` block in your functions instead of the simpler `function Foo($Arg1, $Arg2){`, example:
3. If your code makes use of `using ...` it needs to be the very first stuff to be ran,
(e.g `Invoke-NGENPosh` uses namepace `System.Management.Automation`), add it to the build script


```PowerShell
function Foo {
    param(
        [String]$Path,
        [Switch]$ShowWidgets
    )
    # ...
}
```

# TweakList-UI

In order for your function to be properly formatted and showcased on [TweakList-UI](https://github.com/couleur-tweak-tips/TweakList-UI), you must follow these guidelines:

Each function which has a multiline comment header (`<# .. #>`) makes it automatically parsed by `/buildManifests.ps1` and structured in `./Manifests.json` for it to be used by TweakList-UI

Between your ``function Verb-Noun {`` and the start of your `param` block, you can put a multiline command (`<#`, `#>`),
then format it like so:
```PowerShell
<#
    .SYNOPSIS
    Category: Optimizations
    Platform: Windows; Linux; Your mom's 2008 Dell PDC-91
    Display Name: Verb Noun

    .DESCRIPTION
    This incredible tweak will multiply your gigashits by ^10 😳
        - (149.99£ or 15,000 Hone invites, no refunds)

    .PARAMETER ARG1
    Specify weight of gigashit
    1KG: Will be enough to multiply it by 2
    2KG: Will put CTT out of business
    10KG: Not tested, reminder that we are not liable for any explosion due to the use of TweakList on your computer
#>
```
Values are separated by a colon and a space, multiple values (e.g see `Platform: `) MUST be separated by a semi-colon and a space


# Common PowerShell pitfalls

PowerShell was made to replace batch, but you can still use some batch commands in PowerShell by typing ``cmd /c`` before them

```bat
cmd /c assoc .ps1
```

assoc is a specific batch command, but a lot of other commands can be used in PowerShell as well because they're just executables in System32 (PING.exe, tracert.exe, timeout.exe, setx.exe, shutdown.exe reg.exe, tskill.exe,)

If you're only familiar with handling the registry in batch, you'll only have to change your fancy for and if statements, ``REG.EXE`` can be used the same way on PowerShell

## PowerShell 5.1 alias overrides

-  5.1 is the version of PowerShell that comes with Windows 10/11 

Per default, curl in PowerShell is an alias for the cmdlet ``Invoke-WebRequest``, if you wish to use curl in that version, make sure you specify it's .exe extension

A verbose way to make it cross-platform is to replace it with `$((Get-Command curl -CommandType Application).Source | Select-Object -First 1)`

```
curl.exe -L https://github.com/couleur-tweak-tips/utils/archive/refs/heads/main.zip
```
Same thing for where.exe, which is an alias to Where-Object, just specify it's full cmdlet name.