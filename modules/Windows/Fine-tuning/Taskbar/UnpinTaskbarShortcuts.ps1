# Source: https://github.com/farag2/Sophia-Script-for-Windows

<#
	.SYNOPSIS
	Unpin shortcuts from the taskbar

	.PARAMETER Edge
	Unpin the "Microsoft Edge" shortcut from the taskbar

	.PARAMETER Store
	Unpin the "Microsoft Store" shortcut from the taskbar

	.PARAMETER Mail
	Unpin the "Mail" shortcut from the taskbar

	.EXAMPLE
	UnpinTaskbarShortcuts -Shortcuts Edge, Store, Mail

	.NOTES
	Current user

	.LINK
	https://github.com/Disassembler0/Win10-Initial-Setup-Script/issues/8#issue-227159084
#>
function UnpinTaskbarShortcuts
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateSet("Edge", "Store", "Mail")]
		[string[]]
		$Shortcuts
	)

	# Extract strings from shell32.dll using its' number
	$Signature = @{
		Namespace        = "WinAPI"
		Name             = "GetStr"
		Language         = "CSharp"
		MemberDefinition = @"
[DllImport("kernel32.dll", CharSet = CharSet.Auto)]
public static extern IntPtr GetModuleHandle(string lpModuleName);

[DllImport("user32.dll", CharSet = CharSet.Auto)]
internal static extern int LoadString(IntPtr hInstance, uint uID, StringBuilder lpBuffer, int nBufferMax);

public static string GetString(uint strId)
{
	IntPtr intPtr = GetModuleHandle("shell32.dll");
	StringBuilder sb = new StringBuilder(255);
	LoadString(intPtr, strId, sb, sb.Capacity);
	return sb.ToString();
}
"@
	}
	if (-not ("WinAPI.GetStr" -as [type]))
	{
		Add-Type @Signature -Using System.Text
	}

	# Extract the localized "Unpin from taskbar" string from shell32.dll
	$LocalizedString = [WinAPI.GetStr]::GetString(5387)

	foreach ($Shortcut in $Shortcuts)
	{
		switch ($Shortcut)
		{
			Edge
			{
				if (Test-Path -Path "$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk")
				{
					# Call the shortcut context menu item
					$Shell = (New-Object -ComObject Shell.Application).NameSpace("$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar")
					$Shortcut = $Shell.ParseName("Microsoft Edge.lnk")
					$Shortcut.Verbs() | Where-Object -FilterScript {$_.Name -eq $LocalizedString} | ForEach-Object -Process {$_.DoIt()}
				}
			}
			Store
			{
				# Start-Job is used due to that the calling this function before UninstallUWPApps breaks the retrieval of the localized UWP apps packages names
				Start-Job -ScriptBlock {
					$Apps = (New-Object -ComObject Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}").Items()
					($Apps | Where-Object -FilterScript {$_.Name -eq "Microsoft Store"}).Verbs() | Where-Object -FilterScript {$_.Name -eq $Using:LocalizedString} | ForEach-Object -Process {$_.DoIt()}
				} | Receive-Job -Wait -AutoRemoveJob
			}
			Mail
			{
				# Start-Job is used due to that the calling this function before UninstallUWPApps breaks the retrieval of the localized UWP apps packages names
				if (Get-AppxPackage -Name microsoft.windowscommunicationsapps)
				{
					Start-Job -ScriptBlock {
						$Apps = (New-Object -ComObject Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}").Items()
						($Apps | Where-Object -FilterScript {$_.Path -eq "microsoft.windowscommunicationsapps_8wekyb3d8bbwe!microsoft.windowslive.mail"}).Verbs() | Where-Object -FilterScript {$_.Name -eq $Using:LocalizedString} | ForEach-Object -Process {$_.DoIt()}
					} | Receive-Job -Wait -AutoRemoveJob
				}
			}
		}
	}
}