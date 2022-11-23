function Write-Color {
    param(
        [String]$Message
    )
    $E = [char]0x1b
    $Presets = [Ordered]@{
        '&RESET'   ="$E[0m"
        '&BOLD'    ="$E[1m"
        '&ITALIC'  ="$E[3m"
        '&URL'     ="$E[4m"
        '&BLINK'   ="$E[5m"
        '&ALTBLINK'="$E[6m"
        '&SELECTED'="$E[7m"
        '@BLACK'   ="$E[30m"
        '@RED'     ="$E[31m"
        '@GREEN'   ="$E[32m"
        '@YELLOW'  ="$E[33m"
        '@BLUE'    ="$E[34m"
        '@VIOLET'  ="$E[35m"
        '@BEIGE'   ="$E[36m"
        '@WHITE'   ="$E[37m"
        '@GREY'    ="$E[90m"
        '@LRED'    ="$E[91m"
        '@LGREEN'  ="$E[92m"
        '@LYELLOW' ="$E[93m"
        '@LBLUE'   ="$E[94m"
        '@LVIOLET' ="$E[95m"
        '@LBEIGE'  ="$E[96m"
        '@LWHITE'  ="$E[97m"
        '%BLACK'   ="$E[40m"
        '%RED'     ="$E[41m"
        '%GREEN'   ="$E[42m"
        '%YELLOW'  ="$E[43m"
        '%BLUE'    ="$E[44m"
        '%VIOLET'  ="$E[45m"
        '%BEIGE'   ="$E[46m"
        '%WHITE'   ="$E[47m"
        '%GREY'    ="$E[100m"
        '%LRED'    ="$E[101m"
        '%LGREEN'  ="$E[102m"
        '%LYELLOW' ="$E[103m"
        '%LBLUE'   ="$E[104m"
        '%LVIOLET' ="$E[105m"
        '%LBEIGE'  ="$E[106m"
        '%LWHITE'  ="$E[107m"
    }
    Foreach($Pattern in $Presets.Keys){
        $Message = $Message -replace $Pattern, $Presets.$Pattern
    }
    return $Message + $Presets.'$RESET'
}
