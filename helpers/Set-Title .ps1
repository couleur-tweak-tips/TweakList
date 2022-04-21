function Set-Title ($Title) {
    Invoke-Expression "$Host.UI.RawUI.WindowTitle = `"TweakList - `$(`$MyInvocation.MyCommand.Name) [$Title]`""
}
