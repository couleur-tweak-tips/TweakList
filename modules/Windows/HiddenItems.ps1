<#
	.SYNOPSIS
	Set weither to show or hide files, folders, and drives

#>
function HiddenItems
{
	param
	(
		[Parameter(
			Mandatory = $true,
			ParameterSetName = "Shown"
		)]
		[switch]
		$Shown,

		[Parameter(
			Mandatory = $true,
			ParameterSetName = "Hidden"
		)]
		[switch]
		$Hidden
	)

	switch ($PSCmdlet.ParameterSetName)
	{
		"Shown"
		{
			New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -PropertyType DWord -Value 1 -Force
		}
		"Hidden"
		{
			New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -PropertyType DWord -Value 2 -Force
		}
	}
}