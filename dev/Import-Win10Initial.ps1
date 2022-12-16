
<#
	.SYNOPSIS
	Scraps the latest version of Disassembler0's Win10-Initial-Setup-Script, then formats and imports it as a module
#>
function Import-Win10Initial {
    [CmdletBinding()]
    param(
        [String]$RawPSM1 = 'https://github.com/Disassembler0/Win10-Initial-Setup-Script/raw/master/Win10.psm1',
        [Switch]$Write # Return formatted module instead of importing it
    )
    $Script = Invoke-RestMethod $RawPSM1 -ErrorAction Stop

    ## We get all info from the functions
    $FunctionData = [ScriptBlock]::Create(($Script)).
            Ast.FindAll({
                param ($node)
                $node.GetType().Name -eq 'FunctionDefinitionAst'
            }, $true) # Grabs each function


    # Format each of them
    $ScriptList = $Script -split "`n" # Used with linecount to grab the Description
    $Tweaks = [Collections.ArrayList]::New()

    ForEach($Function in $FunctionData){

        $Body = $Function.Body.Extent.Text.TrimStart("{").TrimEnd("}") -split "`n" |
            Where-Object {($_.Trim())} # Keeps out lines trimmed that don't contain any code
        

        $Data = [Ordered]@{
            Name =   $Function.Name
            Extent = $Function.Extent.Text
            Body = $Body -join "`n"
        }

        # First line contains basic info
        if ($Body[0].Trim() -like "Write-Output `"*"){
            $Synopsis = ($Body[0].Trim() -replace 'Write-Output', '' -replace '"', '' -replace '\.\.\.', '').Trim()
            $Data += @{Synopsis = $Synopsis}
            
        }

        # If there's comments before the function, grab it
        if ($ScriptList[$Function.Extent.StartLineNumber - 2] -Like "# *"){
            $Description = [Collections.ArrayList]::New()
            for ($i = 2; $true; $i++){
                $Line = $ScriptList[$Function.Extent.StartLineNumber - $i]
                if ($Line -like "# *"){
                    $FormattedLine = $Line -replace "# "
                    if ($FormattedLine -eq $Data.Synopsis){
                        continue
                    }
                    $Description += $FormattedLine
                }else {break} # not a comment anymore, end
            }
            if ($Description){ # then it managed to parse stuff
                [Array]::Reverse($Description) # Because we're going back up
                $Data += @{Description = ($Description)}
            }
        }

        $Tweaks += $Data

    }

    $FakeModule = [Collections.ArrayList]::New()
# not intended because use of here-strings
ForEach ($Tweak in $Tweaks){
    $FakeFunction = ""
    if ($Tweak.Synopsis){
        $FakeFunction = @"
<#
    .SYNOPSIS
    $($Tweak.Synopsis)
"@
    }
    if ($Tweak.Description){
        $FakeFunction += @"

    .DESCRIPTION
    $($Tweak.Description | ForEach-Object {"    $_`n"})
#>
"@
    }else {
        $FakeFunction += "#>"
    }
    $FakeFunction += "`n" + $Tweak.Extent
    $FakeModule += $FakeFunction
}

    if ($ReturnModule){
        return $FakeModule
    }

    New-Module -Name "Win10 Initial Setup (TL)" -ScriptBlock ([ScriptBlock]::Create($FakeModule)) | Import-Module -Global

}