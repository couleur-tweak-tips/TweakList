<#
	.SYNOPSIS
	App suggestions in the Start menu

	.PARAMETER Hide
	Hide app suggestions in the Start menu

	.PARAMETER Show
	Show app suggestions in the Start menu

	.EXAMPLE
	AppSuggestions -Hide

	.EXAMPLE
	AppSuggestions -Show

	.NOTES
	Current user
#>
function AppSuggestions
{
	param
	(
		[Parameter(
			Mandatory = $true,
			ParameterSetName = "Hide"
		)]
		[switch]
		$Hide,

		[Parameter(
			Mandatory = $true,
			ParameterSetName = "Show"
		)]
		[switch]
		$Show
	)

	switch ($PSCmdlet.ParameterSetName)
	{
		"Hide"
		{
			New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SubscribedContent-338388Enabled -PropertyType DWord -Value 0 -Force
		}
		"Show"
		{
			New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SubscribedContent-338388Enabled -PropertyType DWord -Value 1 -Force
		}
	}
}