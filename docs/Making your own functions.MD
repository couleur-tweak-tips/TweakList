# Making your own functions

Every code in the functions must be inside of a function declaration (so it does not run when dot-sourcing the function at import)


PowerShell was made to replace batch, but you can still use some batch commands in PowerShell by typing ``cmd /c`` before them

```bat
cmd /c assoc .ps1
```

assoc is a specific batch command, but a lot of other commands can be used in PowerShell as well because they're actually executables in System32 (PING.exe, tracert.exe, timeout.exe, setx.exe, shutdown.exe reg.exe, tskill.exe,)

If you're only familiar with handling the registry in batch, you'll only have to change your fancy for and if statements, REG.EXE can be used the same way on PowerShell

## PowerShell 5.1 alias overrides

-  5.1 is the version of PowerShell that comes with Windows 10/11 

Per default, curl in PowerShell is an alias for Invoke-WebRequest, if you wish to use curl in that version, make sure you specify it's .exe extension

```
curl.exe -L https://github.com/couleur-tweak-tips/utils/archive/refs/heads/main.zip
```
Same thing for where.exe, which is an alias to Where-Object, just specify it's extension.