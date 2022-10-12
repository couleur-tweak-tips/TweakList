<#
	.LINK
	Frankensteined from Inestic's WindowsFeatures Sophia Script function
	https://github.com/Inestic
	https://github.com/farag2/Sophia-Script-for-Windows/blob/06a315c643d5939eae75bf6e24c3f5c6baaf929e/src/Sophia_Script_for_Windows_10/Module/Sophia.psm1#L4946

	.SYNOPSIS
	User gets a nice checkbox-styled menu in where they can select 
	
	.EXAMPLE

	Screenshot: https://i.imgur.com/zrCtR3Y.png

	$ToInstall = Invoke-CheckBox -Items "7-Zip", "PowerShell", "Discord"

	Or you can have each item have a description by passing an array of hashtables:

	$ToInstall = Invoke-CheckBox -Items @(

		@{
			DisplayName = "7-Zip"
			# Description = "Cool Unarchiver"
		},
		@{
			DisplayName = "Windows Sandbox"
			Description = "Windows' Virtual machine"
		},
		@{
			DisplayName = "Firefox"
			Description = "A great browser"
		},
		@{
			DisplayName = "PowerShell 777"
			Description = "PowerShell on every system!"
		}
	)
#>
function Invoke-Checkbox{
param(
	$Title = "Select an option",
	$ButtonName = "Confirm",
	$Items = @("Fill this", "With passing an array", "to the -Item param!")
)

if (!$Items.Description){
	$NewItems = @()
	ForEach($Item in $Items){
		$NewItems += @{DisplayName = $Item}
	}
	$Items = $NewItems
} 

Add-Type -AssemblyName PresentationCore, PresentationFramework

# Initialize an array list to store the selected Windows features
$SelectedFeatures = New-Object -TypeName System.Collections.ArrayList($null)
$ToReturn = New-Object -TypeName System.Collections.ArrayList($null)


#region XAML Markup
# The section defines the design of the upcoming dialog box
[xml]$XAML = '
<Window
	xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
	xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
	Name="Window"
	MinHeight="450" MinWidth="400"
	SizeToContent="WidthAndHeight" WindowStartupLocation="CenterScreen"
	TextOptions.TextFormattingMode="Display" SnapsToDevicePixels="True"
	FontFamily="Arial" FontSize="16" ShowInTaskbar="True"
	Background="#F1F1F1" Foreground="#262626">

	<Window.TaskbarItemInfo>
		<TaskbarItemInfo/>
	</Window.TaskbarItemInfo>
	
	<Window.Resources>
		<Style TargetType="StackPanel">
			<Setter Property="Orientation" Value="Horizontal"/>
			<Setter Property="VerticalAlignment" Value="Top"/>
		</Style>
		<Style TargetType="CheckBox">
			<Setter Property="Margin" Value="10, 10, 5, 10"/>
			<Setter Property="IsChecked" Value="True"/>
		</Style>
		<Style TargetType="TextBlock">
			<Setter Property="Margin" Value="5, 10, 10, 10"/>
		</Style>
		<Style TargetType="Button">
			<Setter Property="Margin" Value="25"/>
			<Setter Property="Padding" Value="15"/>
		</Style>
		<Style TargetType="Border">
			<Setter Property="Grid.Row" Value="1"/>
			<Setter Property="CornerRadius" Value="0"/>
			<Setter Property="BorderThickness" Value="0, 1, 0, 1"/>
			<Setter Property="BorderBrush" Value="#000000"/>
		</Style>
		<Style TargetType="ScrollViewer">
			<Setter Property="HorizontalScrollBarVisibility" Value="Disabled"/>
			<Setter Property="BorderBrush" Value="#000000"/>
			<Setter Property="BorderThickness" Value="0, 1, 0, 1"/>
		</Style>
	</Window.Resources>
	<Grid>
		<Grid.RowDefinitions>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="*"/>
			<RowDefinition Height="Auto"/>
		</Grid.RowDefinitions>
		<ScrollViewer Name="Scroll" Grid.Row="0"
			HorizontalScrollBarVisibility="Disabled"
			VerticalScrollBarVisibility="Auto">
			<StackPanel Name="PanelContainer" Orientation="Vertical"/>
		</ScrollViewer>
		<Button Name="Button" Grid.Row="2"/>
	</Grid>
</Window>
'
#endregion XAML Markup

$Form = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$XAML.SelectNodes("//*[@Name]") | ForEach-Object {
	Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)
}

#region Functions
function Get-CheckboxClicked
{
	[CmdletBinding()]
	param
	(
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $true
		)]
		[ValidateNotNull()]
		$CheckBox
	)

	$Feature = $Items | Where-Object -FilterScript {$_.DisplayName -eq $CheckBox.Parent.Children[1].Text}

	if ($CheckBox.IsChecked)
	{
		[void]$SelectedFeatures.Add($Feature)
	}
	else
	{
		[void]$SelectedFeatures.Remove($Feature)
	}
	if ($SelectedFeatures.Count -gt 0)
	{
		$Button.Content = $ButtonName
		$Button.IsEnabled = $true
	}
	else
	{
		$Button.Content = "Cancel"
		$Button.IsEnabled = $true
	}
}

function DisableButton
{
	[void]$Window.Close()

	#$SelectedFeatures | ForEach-Object -Process {Write-Verbose $_.DisplayName -Verbose}
	$SelectedFeatures.DisplayName
	$ToReturn.Add($SelectedFeatures.DisplayName)
}

function Add-FeatureControl
{
	[CmdletBinding()]
	param
	(
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $true
		)]
		[ValidateNotNull()]
		$Feature
	)

	process
	{
		$CheckBox = New-Object -TypeName System.Windows.Controls.CheckBox
		$CheckBox.Add_Click({Get-CheckboxClicked -CheckBox $_.Source})
		if ($Feature.Description){
			$CheckBox.ToolTip = $Feature.Description
		}

		$TextBlock = New-Object -TypeName System.Windows.Controls.TextBlock
		#$TextBlock.On_Click({Get-CheckboxClicked -CheckBox $_.Source})
		$TextBlock.Text = $Feature.DisplayName
		if ($Feature.Description){
			$TextBlock.ToolTip = $Feature.Description
		}

		$StackPanel = New-Object -TypeName System.Windows.Controls.StackPanel
		[void]$StackPanel.Children.Add($CheckBox)
		[void]$StackPanel.Children.Add($TextBlock)
		[void]$PanelContainer.Children.Add($StackPanel)

		$CheckBox.IsChecked = $false

		# If feature checked add to the array list
		[void]$SelectedFeatures.Add($Feature)
		$SelectedFeatures.Remove($Feature)
	}
}
#endregion Functions

# Getting list of all optional features according to the conditions


# Add-Type -AssemblyName System.Windows.Forms



# if (-not ("WinAPI.ForegroundWindow" -as [type]))
# {
# 	Add-Type @SetForegroundWindow
# }

# Get-Process | Where-Object -FilterScript {$_.Id -eq $PID} | ForEach-Object -Process {
# 	# Show window, if minimized
# 	[WinAPI.ForegroundWindow]::ShowWindowAsync($_.MainWindowHandle, 10)

# 	#Start-Sleep -Seconds 1

# 	# Force move the console window to the foreground
# 	[WinAPI.ForegroundWindow]::SetForegroundWindow($_.MainWindowHandle)

# 	#Start-Sleep -Seconds 1

# 	# Emulate the Backspace key sending
# 	[System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE 1}")
# }
# #endregion Sendkey function

$Window.Add_Loaded({$Items | Add-FeatureControl})
$Button.Content = $ButtonName
$Button.Add_Click({& DisableButton})
$Window.Title = $Title

# ty chrissy <3 https://blog.netnerds.net/2016/01/adding-toolbar-icons-to-your-powershell-wpf-guis/
$base64 = "iVBORw0KGgoAAAANSUhEUgAAACoAAAAqCAMAAADyHTlpAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAPUExURQAAAP///+vr6+fn5wAAAD8IT84AAAAFdFJOU/////8A+7YOUwAAAAlwSFlzAAALEwAACxMBAJqcGAAAANBJREFUSEut08ESgjAMRVFQ/v+bDbxLm9Q0lRnvQtrkDBt1O4a2FoNWHIBajJW/sQ+xOnNnlkMsrXZkkwRolHHaTXiUYfS5SOgXKfuQci0T5bLoIeWYt/O0FnTfu62pyW5X7/S26D/yFca19AvBXMaVbrnc3n6p80QGq9NUOqtnIRshhi7/ffHeK0a94TfQLQPX+HO5LVef0cxy8SX/gokU/bIcQvxjB5t1qYd0aYWuz4XF6FHam/AsLKDTGWZpuWNqWZ358zdmrOLNAlkM6Dg+78AGkhvs7wgAAAAASUVORK5CYII="
 
 
# Create a streaming image by streaming the base64 string to a bitmap streamsource
$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64)
$bitmap.EndInit()
$bitmap.Freeze()

# This is the icon in the upper left hand corner of the app
# $Form.Icon = $bitmap
 
# This is the toolbar icon and description
$Form.TaskbarItemInfo.Overlay = $bitmap
$Form.TaskbarItemInfo.Description = $window.Title

# # Force move the WPF form to the foreground
# $Window.Add_Loaded({$Window.Activate()})
# $Form.ShowDialog() | Out-Null
# return $ToReturn

# [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($Form)

Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration
$window.Add_Closing({[System.Windows.Forms.Application]::Exit()})

$Form.Show()

# This makes it pop up
$Form.Activate() | Out-Null
 
# Create an application context for it to all run within. 
# This helps with responsiveness and threading.
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext) 
return $ToReturn
}