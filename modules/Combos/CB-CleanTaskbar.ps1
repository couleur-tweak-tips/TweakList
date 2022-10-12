function CB-CleanTaskbar {
	if (-Not(Get-Module -Name "Sophia Script (TL)" -Ea 0)){
		Import-Sophia
	}
	CortanaButton -Hide
	PeopleTaskbar -Hide
	TaskBarSearch -Hide
	TaskViewButton -Hide
	UnpinTaskbarShortcuts Edge, Store, Mail

	# Remove "Meet now" from the taskbar, s/o privacy.sexy
	Set-ItemProperty -Path "Registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Value 1
}