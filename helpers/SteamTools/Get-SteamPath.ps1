Function Get-SteamPath {
	return (Get-Item HKCU:\Software\Valve\Steam\).GetValue("SteamPath").Replace("/","\")
}