# Making your own TweakList

## Setting up VSCode

If you want to be comfortable while making your very own list of tweaks, I strongly recommend you to install [VSCode](https://code.visualstudio.com) with the [PowerShell extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell), import the functions one time to get them loaded so you have the function's parameters' autocompletion.

Alternatively you can use [Notepad++](https://notepad-plus-plus.org/) which has syntax highlighting.


You can alternatively install it with Scoop or Chocolatey:
```PowerShell
iex(irm tl.ctt.cx); get extras/vscode
```

```PowerShell
chocolatey install vscode -y
```

## The tweaklist itself

Every tweaklist start with the following line:

```PowerShell
irm tl.ctt.cx | iex
```
> If you're getting errors about a failed TLS handshake, put in ``[System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'`` before (some old Windows builds don't enforce TLS 1.2)

This will get ./Master.ps1 from the repository, and imports the code as a module

### The functions and their parameters

The best way to learn how to use them is by looking at other people's tweaklists and the code behind the functions themselves, I've left a bunch of comments on them to make it easier to understand what's going on.

Every parameter needs a `-` before them, example:

```PowerShell
FileExtensions -Show
```
This will run the FileExtensions function with the Show parameter, it'll go in the registry and edit the value for it to show file extensions in Windows.

This type of parameter is a ``switch``, it is declared at the start of the function as a variable with [switch] before it. When running the function with it, the variable $Show will be equal to the $true (PowerShell boolean uses variable :shrug:)

You can also pass in arrays of strings like so:

```PowerShell
Remove-KnownAppxPackages -Exclude Calculator, MicrosoftStore
```