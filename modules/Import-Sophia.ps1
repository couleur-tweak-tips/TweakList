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

	$SophiaVer = "Sophia Script for " # Gets appended with the correct win/ps version in the very next switch statement

switch ((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber){

	17763 {$SophiaVer += "Windows_10_LTSC_2019"}
	
	{($_ -ge 19041) -and ($_ -le 19044)}{

		if ($PSVersionTable.PSVersion.Major -eq 5){

			# Check if Windows 10 is an LTSC 2021
			if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName) -eq "Windows 10 Enterprise LTSC 2021"){

				$SophiaVer += "Windows_10_LTSC_2021"
			}else{

				$SophiaVer += "Windows_10"
			}
		}else{

			Write-Warning "PowerShell 7 core has not been tested as thoroughly, give Windows PowerShell a try if you're having issues"
			$SophiaVer += "Windows_10_PowerShell_7"
		}

	}
	22000 {

		if ($PSVersionTable.PSVersion.Major -eq 5){

			$SophiaVer += "Windows_11"
		}else{

			Write-Warning "PowerShell 7 core has not been tested as thoroughly, give Windows PowerShell a try if you're having issues"
			$SophiaVer +="Windows_11_PowerShell_7"
		}
	}
}



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
		$Hashtable = Invoke-RestMethod "https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/master/src/$($SophiaVer -Replace ' ','_')/Localizations/$Lang/Sophia.psd1" -ErrorAction Stop
	} Catch {
		Write-Warning "Failed to get Localizations with lang $Lang"
		return
	}
	While ($Hashtable[0] -ne 'C'){
		$Hashtable = $Hashtable.Substring(1) # BOM ((
	}
	$global:Localizations = $global:Localization = Invoke-Expression $HashTable

	Write-Verbose "Getting $SophiaVer"

	$RawURL = "https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/master/src/$($SophiaVer -Replace ' ','_')/Module/Sophia.psm1"
	Write-Verbose $RawURL

	$SophiaFunctions = (Invoke-RestMethod $RawURL -ErrorAction Stop)

	While ($SophiaFunctions[0] -ne '<'){
		$SophiaFunctions = $SophiaFunctions.Substring(1) # BOM ((
	}

	if ($Write){
		return $SophiaFunctions
	}else{
		New-Module -Name "Sophia Script (TL)" -ScriptBlock ([ScriptBlock]::Create($SophiaFunctions)) | Import-Module
	}

}