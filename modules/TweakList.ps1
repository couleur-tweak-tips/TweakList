function TweakList {
    [alias('tl')]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [System.Collections.Arraylist]
        $Arguments
    )
    $shortcuts = @{
        repo = {Start-Process https://github.com/couleur-tweak-tips/TweakList}
        ui   = {Start-Process https://couleur-tweak-tips.github.io/TweakList-UI}
    }
    if ($Arguments){
        if ($Arguments[0] -in [String[]]$shortcuts.Keys){
            & $shortcuts.($Arguments[0])
        }else {
            Write-Host "Available shortcuts:"
            $shortcuts
        }
        return
    }

return @"
Welcome to TweakList! If you're seeing this in your terminal, then you're
already able to start calling all your functions. You can learn how to use
TweakList on: https://github.com/couleur-tweak-tips/TweakList/tree/master/docs

If you're curious what a function actually does, use 'gfc' (aka Get-FunctionContent)
with the name of the function you want to see. Example:

PS X:\> Get-FunctionContent Import-Sophia

All functions have aliases, if you're using TL a lot: learn em all!

You can use the TweakList function (AKA tl) to do the following:

tl repo opens TweakList's repo
tl ui opens the UI


"@
}