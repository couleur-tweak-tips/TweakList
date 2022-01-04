function OneDrive
{
	param
	(
		[Parameter(
			Mandatory = $true,
			ParameterSetName = "Uninstall"
		)]
		[switch]
		$Uninstall,

		[Parameter(
			Mandatory = $true,
			ParameterSetName = "Install"
		)]
		[switch]
		$Install
	)

	switch ($PSCmdlet.ParameterSetName)
	{
		"Uninstall"
		{
			[string]$UninstallString = Get-Package -Name "Microsoft OneDrive" -ProviderName Programs -ErrorAction Ignore | ForEach-Object -Process {$_.Meta.Attributes["UninstallString"]}
			if ($UninstallString)
			{
				Write-Information -MessageData "" -InformationAction Continue
				Write-Verbose -Message $Localization.OneDriveUninstalling -Verbose

				Stop-Process -Name OneDrive -Force -ErrorAction Ignore
				Stop-Process -Name OneDriveSetup -Force -ErrorAction Ignore
				Stop-Process -Name FileCoAuth -Force -ErrorAction Ignore

				# Getting link to the OneDriveSetup.exe and its' argument(s)
				[string[]]$OneDriveSetup = ($UninstallString -Replace("\s*/",",/")).Split(",").Trim()
				if ($OneDriveSetup.Count -eq 2)
				{
					Start-Process -FilePath $OneDriveSetup[0] -ArgumentList $OneDriveSetup[1..1] -Wait
				}
				else
				{
					Start-Process -FilePath $OneDriveSetup[0] -ArgumentList $OneDriveSetup[1..2] -Wait
				}

				# Get the OneDrive user folder path and remove it if it doesn't contain any user files
				if (Test-Path -Path $env:OneDrive)
				{
					if ((Get-ChildItem -Path $env:OneDrive -ErrorAction Ignore | Measure-Object).Count -eq 0)
					{
						Remove-Item -Path $env:OneDrive -Recurse -Force -ErrorAction Ignore

						# https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-movefileexa
						# The system does not move the file until the operating system is restarted
						# The system moves the file immediately after AUTOCHK is executed, but before creating any paging files
						$Signature = @{
							Namespace        = "WinAPI"
							Name             = "DeleteFiles"
							Language         = "CSharp"
							MemberDefinition = @"
public enum MoveFileFlags
{
	MOVEFILE_DELAY_UNTIL_REBOOT = 0x00000004
}

[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, MoveFileFlags dwFlags);

public static bool MarkFileDelete (string sourcefile)
{
	return MoveFileEx(sourcefile, null, MoveFileFlags.MOVEFILE_DELAY_UNTIL_REBOOT);
}
"@
						}

						# If there are some files or folders left in %LOCALAPPDATA%\Temp
						if ((Get-ChildItem -Path $env:OneDrive -ErrorAction Ignore | Measure-Object).Count -ne 0)
						{
							if (-not ("WinAPI.DeleteFiles" -as [type]))
							{
								Add-Type @Signature
							}

							try
							{
								Remove-Item -Path $env:OneDrive -Recurse -Force -ErrorAction Stop
							}
							catch
							{
								# If files are in use remove them at the next boot
								Get-ChildItem -Path $env:OneDrive -Recurse -Force | ForEach-Object -Process {[WinAPI.DeleteFiles]::MarkFileDelete($_.FullName)}
							}
						}
					}
					else
					{
						# Invoke-Item doesn't work
						Start-Process -FilePath explorer -ArgumentList $env:OneDrive
					}
				}

				Remove-ItemProperty -Path HKCU:\Environment -Name OneDrive, OneDriveConsumer -Force -ErrorAction Ignore
				Remove-Item -Path HKCU:\SOFTWARE\Microsoft\OneDrive -Recurse -Force -ErrorAction Ignore
				Remove-Item -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive -Recurse -Force -ErrorAction Ignore
				Remove-Item -Path "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction Ignore
				Remove-Item -Path $env:SystemDrive\OneDriveTemp -Recurse -Force -ErrorAction Ignore
				Unregister-ScheduledTask -TaskName *OneDrive* -Confirm:$false -ErrorAction Ignore

				# Getting the OneDrive folder path
				$OneDriveFolder = Split-Path -Path (Split-Path -Path $OneDriveSetup[0] -Parent)

				# Save all opened folders in order to restore them after File Explorer restarting
				Clear-Variable -Name OpenedFolders -Force -ErrorAction Ignore
				$Script:OpenedFolders = {(New-Object -ComObject Shell.Application).Windows() | ForEach-Object -Process {$_.Document.Folder.Self.Path}}.Invoke()

				# Terminate the File Explorer process
				New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoRestartShell -Value 0 -Force
				Stop-Process -Name explorer -Force

				Start-Sleep -Seconds 3

				# Restoring closed folders
				foreach ($Script:OpenedFolder in $Script:OpenedFolders)
				{
					if (Test-Path -Path $Script:OpenedFolder)
					{
						Invoke-Item -Path $Script:OpenedFolder
					}
				}

				New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoRestartShell -Value 1 -Force

				# Attempt to unregister FileSyncShell64.dll and remove
				$FileSyncShell64dlls = Get-ChildItem -Path "$OneDriveFolder\*\amd64\FileSyncShell64.dll" -Force
				foreach ($FileSyncShell64dll in $FileSyncShell64dlls.FullName)
				{
					Start-Process -FilePath regsvr32.exe -ArgumentList "/u /s $FileSyncShell64dll" -Wait
					Remove-Item -Path $FileSyncShell64dll -Force -ErrorAction Ignore

					if (Test-Path -Path $FileSyncShell64dll)
					{
						if (-not ("WinAPI.DeleteFiles" -as [type]))
						{
							Add-Type @Signature
						}

						# If files are in use remove them at the next boot
						Get-ChildItem -Path $FileSyncShell64dll -Recurse -Force | ForEach-Object -Process {[WinAPI.DeleteFiles]::MarkFileDelete($_.FullName)}
					}
				}

				Start-Sleep -Seconds 1

				# Start the File Explorer process
				Start-Process -FilePath explorer

				# Restoring closed folders
				foreach ($OpenedFolder in $OpenedFolders)
				{
					if (Test-Path -Path $OpenedFolder)
					{
						# Invoke-Item doesn't work
						Start-Process -FilePath explorer -ArgumentList $OpenedFolder
					}
				}

				Remove-Item -Path $OneDriveFolder -Recurse -Force -ErrorAction Ignore
				Remove-Item -Path $env:LOCALAPPDATA\OneDrive -Recurse -Force -ErrorAction Ignore
				Remove-Item -Path $env:LOCALAPPDATA\Microsoft\OneDrive -Recurse -Force -ErrorAction Ignore
				Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Force -ErrorAction Ignore
			}
		}
		"Install"
		{
			$OneDrive = Get-Package -Name "Microsoft OneDrive" -ProviderName Programs -Force -ErrorAction Ignore
			if (-not $OneDrive)
			{
				if (Test-Path -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe)
				{
					Write-Information -MessageData "" -InformationAction Continue
					Write-Verbose -Message $Localization.OneDriveInstalling -Verbose

					Start-Process -FilePath $env:SystemRoot\SysWOW64\OneDriveSetup.exe
				}
				else
				{
					try
					{
						# Check the internet connection
						$Parameters = @{
							Uri              = "https://www.google.com"
							Method           = "Head"
							DisableKeepAlive = $true
							UseBasicParsing  = $true
						}
						if (-not (Invoke-WebRequest @Parameters).StatusDescription)
						{
							return
						}

						# Downloading the latest OneDrive installer 64-bit
						Write-Information -MessageData "" -InformationAction Continue
						Write-Verbose -Message $Localization.OneDriveDownloading -Verbose

						# Parse XML to get the URL
						# https://go.microsoft.com/fwlink/p/?LinkID=844652
						$Parameters = @{
							Uri             = "https://g.live.com/1rewlive5skydrive/OneDriveProduction"
							UseBasicParsing = $true
							Verbose         = $true
						}
						$Content = Invoke-RestMethod @Parameters

						# Remove invalid chars
						[xml]$OneDriveXML = $Content -replace "ï»¿", ""

						$OneDriveURL = ($OneDriveXML).root.update.amd64binary.url[-1]
						$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
						$Parameters = @{
							Uri             = $OneDriveURL
							OutFile         = "$DownloadsFolder\OneDriveSetup.exe"
							UseBasicParsing = $true
							Verbose         = $true
						}
						Invoke-WebRequest @Parameters

						Start-Process -FilePath "$DownloadsFolder\OneDriveSetup.exe" -Wait

						Remove-Item -Path "$DownloadsFolder\OneDriveSetup.exe" -Force
					}
					catch [System.Net.WebException]
					{
						Write-Warning -Message $Localization.NoInternetConnection
						Write-Error -Message $Localization.NoInternetConnection -ErrorAction SilentlyContinue

						Write-Error -Message ($Localization.RestartFunction -f $MyInvocation.Line) -ErrorAction SilentlyContinue
					}
				}

				# Save screenshots by pressing Win+PrtScr in the Pictures folder
				Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{B7BEDE81-DF94-4682-A7D8-57A52620B86F}" -Force -ErrorAction Ignore

				Get-ScheduledTask -TaskName "Onedrive* Update*" | Enable-ScheduledTask
				Get-ScheduledTask -TaskName "Onedrive* Update*" | Start-ScheduledTask
			}
		}
	}
}