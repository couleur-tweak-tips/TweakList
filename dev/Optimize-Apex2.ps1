function Optimize-Apex2{
param(
	[ValidateScript({Test-Path -Path $_ -PathType Leaf})]
	[ValidateScript({(Get-Item $_).Extension -eq ".exe"})]
	[String]$r5apexPath
)

function StartMenu {
	$Lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Apex Legends.lnk" 
	if (-Not(Test-Path $Lnk)){

		return $False
	}
	$ApexDir = (New-Object -ComObject WScript.Shell).CreateShortcut((Get-Item $Lnk -ErrorAction Stop)).TargetPath | Split-Path
	if (-not(Test-Path $ApexDir)){
		return $False
	}else{
		return $ApexDir
	}
}
function MuiCache {

	$Path = "REGISTRY::HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"

	if (-not (Test-Path $Path)){
		return $False
	}
	
	$Key = (Get-ItemProperty $Path -ErrorAction Ignore | Get-Member | Where-Object Name -Like "*r5apex.exe.FriendlyAppName").Name
	if (!$Key){
		return $false
	}else{
		return ($Key.TrimEnd(".FriendlyAppName") | Split-Path)
	}

}

# Looks dumb? Yes, works? As well, let me know a cleaner way 👍
$ApexDir = if (StartMenu){StartMenu}elseif(MuiCache){MuiCache}

if (!$ApexDir){
return @"
Couldn't find Apex Legends' executable (r5apex.exe), please find it yourself,
shift right click it -> Copy As Path and then launch this tweakfunc again with -r5apexPath `"..\common\Apex Legends\r5apex.exe`"
"@
}
}
