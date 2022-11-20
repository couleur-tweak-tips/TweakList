<# This function messes with the message that appears before the commands you type

# Turns:
PS D:\Scoop>
# into
TL D:\Scoop>

To indicate TweakList has been imported

You can prevent this from happening by setting the environment variable TL_NOPROMPT to 1
#>
$global:CSI = [char] 27 + '['
if (!$env:TL_NOPROMPT -and !$TL_NOPROMPT){
    function global:prompt {
            "$CSI`97;7mTL$CSI`m $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    }
}
