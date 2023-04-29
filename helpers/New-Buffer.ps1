Function New-Buffer(
    [Parameter(Mandatory)]
    [ValidateSet("Alternative", "Default")]
    [String]$State) {
    switch ($State) {
        "Alternative" { $Buffer = "$([char]27)[?1049h" }
        "Default" { $Buffer = "$([char]27)[?1049l" }
    }
    Write-Host -NoNewline "$Buffer"
}