function Show-Diff {
	param(
	[String]$Message,
	[Boolean]$Positivity,
	[String]$Term
	)
	$E = [char]0x1b # Ansi ESC character

	if ($Positivity -and !$Term){
		$Sign = '+'
		$Accent = "$E[92m"
		$Term = "Enabled"
	}
	elseif(!$Positivity -and !$Term){
		$Sign = '-'
		$Term = "Removed"
		$Accent = "$E[91m"
	}

	$Gray = "$E[90m"
	$Reset = "$E[0m"

	Write-Host "  $Gray[$Accent$Sign$Gray]$Reset $Term $Accent$Message"
 
}
