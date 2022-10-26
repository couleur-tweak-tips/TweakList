function Launch{
	[alias('l')]
	param(
		[ValidateSet(
			'DisplayDriverUninstaller',
			'NVCleanstall',
			'NvidiaProfileInspector',
			'MSIUtilityV3',
			'Rufus',
			'AutoRuns',
			'Procmon',
			'CustomResolutionUtility',
			'NotepadReplacer',
			'privacy.sexy'
			#! TODO: NVProfileInspector, MSIUtility, CRU, Notepadreplacer, BulkCrapUninstaller, https://www.bill2-software.com/processmanager/exe/BPM-Setup.exe
		)]
		[Array]$Apps,
		[Switch]$DontLaunch, # Just keep them tidy in the Downloads folder))
		# This is the non hardcoded Downloads folder path s/o @farag2
		[String]$OutDir = (Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}")
	)

	Add-Type -AssemblyName System.IO.Compression.FileSystem

	function Invoke-Download{
		param(
			[String]$URL, # Parses mediafire
			[String]$AppName,
			[Switch]$Scoop, # Scoop 'bucket/manifest' name
			[String]$PathToBinary, # In the zip
			[String]$Checksum,
			[String]$SelfExtracting7z # e.g for DDU
		)

		if (-Not(Test-Path $env:TMP)){
			throw "TMP environment variable not found [$env:TMP]"
		}

		if($Scoop){
			$Bucket, $Manifest = $URL -split '/'

			$Repos = @{

				main = @{org = 'ScoopInstaller';repo = 'main';branch = 'master'}
				extras = @{org = 'ScoopInstaller';repo = 'extras';branch = 'master'}
				utils = @{org = 'couleur-tweak-tips';repo = 'utils';branch = 'main'}
				nirsoft = @{org = 'kodybrown';repo = 'scoop-nirsoft';branch = 'master'}
				games = @{org = 'ScoopInstaller';repo = 'games';branch = 'master'}
				'nerd-fonts' = @{org = 'ScoopInstaller';repo = 'nerd-fonts';branch = 'master'}
				versions = @{org = 'ScoopInstaller';repo = 'versions';branch = 'master'}
				java = @{org = 'ScoopInstaller';repo = 'java';branch = 'master'}
			}
			$repo = $Repos.$Bucket
			$URL = "https://raw.githubusercontent.com/$($repo.org)/$($repo.repo)/$($repo.branch)/bucket/$Manifest.json"
			$URL, $Version = Invoke-RestMethod $URL | ForEach-Object {$PSItem.URL, $PSItem.Version}
		}elseif($URL -Like "*mediafire.com*"){
			$URL = (Invoke-WebRequest -UseBasicParsing $URL).Links.href | Where-Object {$PSItem -Like "http*://download*.mediafire.com/*"}
		}

		if ($AppName){
			$FileName = $AppName
		}else{
			$FileName = $Manifest
		}
		
		if ($Version){$FileName += " $Version"}

		$Extension = [io.path]::GetExtension((($URL -replace '#/dl.7z') | Split-Path -Leaf))

		$OutFile = "$env:TMP\$FileName$Extension"
		if (-Not(Test-Path $OutFile)){
			curl.exe -#L -A "Scoop" $URL -o"$OutFile"
		}

		if($Checksum){
			$Parameters = @{
				Path = $OutFile
			}
			if ($Checksum -Like "*:*"){ # Contains a :
				$Algo, $Checksum = $Checksum -Split ':' # To split hash and algo, eg md5:8424509737CEDBDE4BA9E9A780D5CE96
				$Parameters += @{
					Algorithm = $Algo 
				}
			}
			if ($Checksum -ne (Get-FileHash @Parameters).Hash){
				throw "Hash provided $Checksum does not match $OutFile"
			}
		}

		if ($Extension -eq '.zip'){
			$OutDir = "$env:TMP\$FileName\"
			if (-Not(Test-Path $OutDir)){
				[System.IO.Compression.ZipFile]::ExtractToDirectory($OutFile, $OutDir)
			}

			if ($PathToBinary){
				$OutDir = Join-Path $OutDir $PathToBinary
			}
			$OutFile = $OutDir # To not have to check for the following statement twice
		}elseif($SelfExtracting7z){
			Start-Process -FilePath $OutFile -ArgumentList "-y" -Wait
			$SelfExtracting7z = $SelfExtracting7z -replace "%VER%", $Version
			if (-Not(Test-Path "$env:TMP\$SelfExtracting7z" -PathType Container)){
				throw "Self extracting 7-Zip got wrong path: $SelfExtracting7z"
			}
			$OutDir = $SelfExtracting7z
		}

		if (-Not(Test-Path $OutFile)){
			throw "$OutFile could not be found"
		}

		return $OutFile

	}

	$Paths = @()

	$Apps | ForEach-Object { # Cycles through given apps
		Write-Host "getting $PSItem"
		$Paths += switch ($PSItem){
			DisplayDriverUninstaller{ Invoke-Download -URL extras/ddu -Scoop -PathToBinary "Display Driver Uninstaller.exe" -SelfExtracting7z "DDU v%VER%" -AppName DDU }
			NVCleanstall{ Invoke-Download -URL extras/nvcleanstall -Scoop -AppName NVCleanstall -PathToBinary "NVCleanstall.exe" }
			NvidiaProfileInspector{ Invoke-Download -URL extras/nvidia-profile-inspector -Scoop -AppName NvidiaProfileInspector -PathToBinary 'nvidiaProfileInspector.exe' }
			MSIUtilityV3{
				Write-Warning "MSI mode is already applied by default on NVIDIA 1600/2000/3000 GPUs and AMD cards"
				Invoke-Download -URL https://www.mediafire.com/file/ewpy1p0rr132thk/MSI_util_v3.zip/file -AppName "MSIUtilV3" -PathToBinary "MSI_util_v3.exe" -Checksum "md5:8424509737CEDBDE4BA9E9A780D5CE96"
			}
			Rufus{ Invoke-Download -URL extras/rufus -Scoop -AppName rufus}
			AutoRuns{ Invoke-Download -URL https://download.sysinternals.com/files/Autoruns.zip -AppName AutoRuns -PathToBinary Autoruns64.exe }
			Procmon{ Invoke-Download -URL https://download.sysinternals.com/files/ProcessMonitor.zip -AppName Procmon -PathToBinary Procmon64.exe }
			CustomResolutionUtility { Invoke-Download -URL extras/cru -Scoop -AppName CRU -PathToBinary CRU.exe}
			NotepadReplacer { Invoke-Download -URL utils/notepadreplacer -Scoop -AppName NotepadReplacer}
			privacy.sexy { Invoke-Download -URL utils/privacysexy -Scoop -AppName privacysexy}
		}
	}
	return $Paths
}