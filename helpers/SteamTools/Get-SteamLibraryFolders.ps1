Function Get-SteamLibraryFolders()
{
<#
.Synopsis 
	Retrieves library folder paths from .\SteamApps\libraryfolders.vdf
.Description
	Reads .\SteamApps\libraryfolders.vdf to find the paths of all the library folders set up in steam
.Example 
	$libraryFolders = Get-LibraryFolders
	Description 
	----------- 
	Retrieves a list of the library folders set up in steam
#>
	$steamPath = Get-SteamPath
	
	$vdfPath = "$($steamPath)\SteamApps\libraryfolders.vdf"
	
	[array]$libraryFolderPaths = @()
	
	if (Test-Path $vdfPath)
	{
		$libraryFolders = ConvertFrom-VDF (Get-Content $vdfPath -Encoding UTF8) | Select-Object -ExpandProperty libraryfolders
		
		$libraryFolderIds = $libraryFolders | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
		
		ForEach ($libraryId in $libraryFolderIds)
		{
			$libraryFolder = $libraryFolders.($libraryId)
			
			$libraryFolderPaths += $libraryFolder.path.Replace('\\','\')
		}
	}
	
	return $libraryFolderPaths
}

