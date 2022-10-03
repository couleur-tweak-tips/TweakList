function Write-Diff {
	param(
	[String]$Message,
	[Boolean]$Positivity,
	[String]$Term
	)
	$E = [char]0x1b # Ansi ESC character

	if ($Positivity){
		$Sign = '+'
		$Accent = "$E[92m"
		if (!$Term){
		$Term = "Enabled"
		}
	}
	elseif(!$Positivity){
		$Sign = '-'
		if (!$Term){
			$Term = "Removed"
		}
		$Accent = "$E[91m"
	}

	$Gray = "$E[90m"
	$Reset = "$E[0m"

	Write-Host "  $Gray[$Accent$Sign$Gray]$Reset $Term $Accent$Message"
 
}
