function Set-PowerPlan {
    param (
        [string]$URL,
        [switch]$Ultimate
        )

    if ($Ultimate){
        powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
    }elseif($URL){
        if ($URL -Like "http*://cdn.discordapp.com/attachments/*.pow"){
            $DotPow = "$env:TMP\{0}" -f (Split-Path $URL -Leaf)
        }else{
            $DotPow = "$env:TMP\Powerplan $(Get-Random).pow"
        }
        Invoke-WebRequest -Uri $PowURL -OutFile $DotPow
        powercfg -duplicatescheme $DotPow
        powercfg /s $DotPow
    }
}
