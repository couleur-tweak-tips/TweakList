# The prompt function itself isn't 
<# This function messes with the message that appears before the commands you type

# Turns:
PS D:\>
# into
TL D:\>

To obviously indicate TweakList has been imported

You can prevent this from happening
#>
$global:CSI = [char] 27 + '['
if (!$env:TL_NOPROMPT -and !$TL_NOPROMPT){
    function Prompt {
        "$CSI`97;7mTL$CSI`m $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    }
}
