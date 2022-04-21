# Making your own TweakList

## Setting up VSCode

If you want to be comfortable while making your very own list of tweaks, I strongly recommend you install [VSCode](https://code.visualstudio.com/) with the [PowerShell extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell), import the functions one time to get them loaded so you have the function's parameters' autocompletion.

Alternatively you can use [Notepad++](https://notepad-plus-plus.org/) which have some syntax highlighting.


You can alternatively install it with Scoop or Chocolatey:
```
scoop bucket add extras
scoop install vscode
```
```ps
chocolatey install vscode -y
```

## The tweaklist itself

Every tweaklist start with the following line:

```ps
irm ts.ctt.cx | iex
```
> If you're getting errors about a failed TLS handshake, put in ``[System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'`` before (common errors on old Windows build / stripped ISOs)

This will make sure the script is ran as admin, download and extract the repo, and import all the functions. If you already have the latest version installed it'll just directly import them.

### The functions and their parameters

The best way to learn how to use them is by looking at other tweaklists and the code behind the functions themselves, I've left a bunch of comments on them to make it easier to understand what's going on.

Every parameter needs a `-` before them, example:

```ps
FileExtensions -Show
```
This will run the FileExtensions function with the Show parameter, it'll go in the registry and edit the value for it to show file extensions in Windows.

This type of parameter is a ``switch``, it is declared at the start of the function as a variable with [switch] before it. When running the function with it, the variable $Show will be equal to the $true (PowerShell boolean uses variable :shrug:)

You can also pass in strings, arrays and integers:

```powershell
Remove-KnownAppxPackages -Exclude @('Calculator','MicrosoftStore')
```
Strings are always surrounded by single or double strings, arrays are declared with @(), integers/floats are declared as is, as shown above you can put strings and integers in arrays.

---
### I'll add more to this guides as more functions and tweaklists show up and complexify themselves, that's all there is to it for now