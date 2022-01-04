function Set-DarkMode {

	@('AppsUseLightTheme','SystemUsesLightTheme') | 
	
	ForEach-Object {
		New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name $PSItem -PropertyType DWord -Value 0 -Force -ErrorAction Inquire
	}

}