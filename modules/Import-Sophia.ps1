<#
	.SYNOPSIS
	Scraps the latest version of Sophia edition weither you have W10/11/LTSC/PS7,
	changes all function scopes to global and invokes it, as if it were importing it as a module

	You can find farag's dobonhonkerosly big Sophia Script at https://github.com/farag2/Sophia-Script-for-Windows
	And if you'd like using it as a GUI, try out SophiApp:  https://github.com/Sophia-Community/SophiApp
	
	Using the -Write parameter returns the script instead of piping it to Invoke-Expression
	.EXAMPLE
	Import-Sophia
	# Or for short:
	ipso
#>
function Import-Sophia {
	[alias('ipso')]
	[CmdletBinding()]
	param(
		[switch]
        $Write,

		[string]
        [ValidateSet(
            'de-DE',
            'en-US',
            'es-ES',
            'fr-FR',
            'hu-HU',
            'it-IT',
            'pt-BR',
            'ru-RU',
            'tr-TR',
            'uk-UA',
            'zh-CN'
        )]
        $OverrideLang
	)

	function Get-SophiaVersion {

		switch ((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber){
	
			"17763" {
		
				"Windows_10_LTSC_2019"
				break
			}
			{($_ -ge 19044) -and ($_ -le 19048)}{
		
				if ($PSVersionTable.PSVersion.Major -eq 5){
		
					# Check if Windows 10 is an LTSC 2021
					if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName) -eq "Windows 10 Enterprise LTSC 2021"){
		
						"Windows_10_LTSC_2021"
					}
					else{
						"Windows_10"
					}
				}
				else{
					"Windows_10_PowerShell_7"
				}
			}
			{$_ -ge 22000}
			{
				if ($PSVersionTable.PSVersion.Major -eq 5){
					"Windows_11"
				}
				else{
					"Windows_11_PowerShell_7"
				}
			}
		}
	}
	
	$SophiaVer = "Sophia_Script_for_" + (Get-SophiaVersion)



	$SupportedLanguages = @(
		'de-DE',
		'en-US',
		'es-ES',
		'fr-FR',
		'hu-HU',
		'it-IT',
		'pt-BR',
		'ru-RU',
		'tr-TR',
		'uk-UA',
		'zh-CN'
	)

	if($OverrideLang){
		if ($OverrideLang -NotIn $SupportedLanguages){
			Write-Warning "Language $OverrideLang may not be supported."
		}
		$Lang = $OverrideLang
	}
	elseif((Get-UICulture).Name -in $SupportedLanguages){
		$Lang = (Get-UICulture).Name
	}
	elseif((Get-UICulture).Name -eq "en-GB"){
		$Lang = 'en-US'
	}
	else{
		$Lang = 'en-US'
	}

	$Lang = (Get-UICulture).Name
	if ($OverrideLang){$Lang = $OverrideLang}

	if ($Lang -NotIn $SupportedLanguages){
		$Lang = 'en-US'
	}
	Try{
		$URL = "https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/master/src/$SophiaVer/Localizations/$Lang/Sophia.psd1"
		$Hashtable = Invoke-RestMethod $URL -ErrorAction Stop
	} Catch {
		Write-Warning "Failed to get Localizations with lang $Lang`nand URL: $URL"
		$_
		return
	}
	While ($Hashtable[0] -ne 'C'){
		$Hashtable = $Hashtable.Substring(1) # BOM ((
	}
	$global:Localizations = $global:Localization = Invoke-Expression $HashTable

	Write-Verbose "Getting $($SophiaVer -replace '_', ' ')"

	$RawURL = "https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/master/src/$SophiaVer/Module/Sophia.psm1"
	Write-Verbose $RawURL

	$SophiaFunctions = (Invoke-RestMethod $RawURL -ErrorAction Stop)

	While ($SophiaFunctions[0] -ne '<'){
		$SophiaFunctions = $SophiaFunctions.Substring(1) # BOM ((
	}

	if ($Write){
		return $SophiaFunctions
	}else{
		New-Module -Name "Sophia Script (TL)" -ScriptBlock ([ScriptBlock]::Create($SophiaFunctions)) | Import-Module -Global
	}

}