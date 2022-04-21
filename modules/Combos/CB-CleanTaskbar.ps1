function CB-CleanTaskbar {
	Invoke-Expression (Import-Sophia)
	CortanaButton -Hide
	PeopleTaskbar -Hide
	TaskBarSearch -Hide
	TaskViewButton -Hide
	UnpinTaskbarShortcuts Edge, Store, Mail
}