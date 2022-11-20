function Set-Title {
    param(
        $Title
    )
    $Host.UI.RawUI.WindowTitle = "TweakList - $Title"
}
