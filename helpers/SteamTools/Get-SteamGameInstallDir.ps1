function Get-SteamGameInstallDir (
    [Parameter(Mandatory = $true)][string]$Game, 
    [array]$LibraryFolders = (Get-SteamLibraryFolders)) {

    # Get the installation directory of a Steam game.
    foreach ($LibraryFolder in $LibraryFolders) {
        $GameInstallDir = "$LibraryFolder\steamapps\common\$Game"
        if (Test-Path "$($GameInstallDir.ToLower())") {
            return "$GameInstallDir"
        }
    }
}