function PauseNul {
    $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}