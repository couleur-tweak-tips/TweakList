function Assert-Path {
    param(
        $Path
    )
    if (-Not(Test-Path -Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}