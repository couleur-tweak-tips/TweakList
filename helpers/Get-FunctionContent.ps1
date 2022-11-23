function Get-FunctionContent {
    [alias('gfc')]
    [CmdletBinding()]
    param([Parameter()]
        [String[]]$Functions,
        [Switch]$Dependencies,
        [Switch]$ReturnNames
    )

    $FunctionsPassed = [System.Collections.ArrayList]@()
    $Content = [System.Collections.ArrayList]@()

    Get-Command $Functions -ErrorAction Stop | ForEach-Object { # Loop through all functions
        if ($Resolved = $_.ResolvedCommand){ # Checks if $_.ResolveCommand exists, also assigns it to $Resolved
            Write-Verbose "Switching from alias $_ to function $($Resolved.Name)" -Verbose
            $_ = Get-Command $Resolved.Name
        }
        if ($_ -NotIn $FunctionsPassed){ # If it hasn't been looped over yet

            $Content += ($Block = $_.ScriptBlock.Ast.Extent.Text)
                # Assigns function block to $Block and appends to $Content
            
            $FunctionsPassed.Add($_) | Out-Null # So it doesn't get checked again

            if ($Dependencies){

                if (!$TL_FUNCTIONS){
                    if (Get-Module -Name TweakList -ErrorAction Ignore){
                        $TL_FUNCTIONS = [String[]](Get-Module -Name TweakList).ExportedFunctions.Keys
                    }else {
                        throw "TL_FUNCTIONS variable is not defined, which is needed to get available TweakList functions"
                    }
                }

                $AST = [System.Management.Automation.Language.Parser]::ParseInput($Block, [ref]$null, [ref]$null)
                
                $DepMatches = $AST.FindAll({
                        param ($node)
                        $node.GetType().Name -eq 'CommandAst'
                    }, $true) | #It gets all cmdlets from the Abstract Syntax Tree
                ForEach-Object {$_.CommandElements[0].Value} | # Returns their name
                    Where-Object { # Filters out only TweakList functions
                        $_ -In ($TL_FUNCTIONS | Where-Object {$_ -ne $_.Name})

                    } | Select-Object -Unique

                ForEach($Match in $DepMatches){
                    $FunctionsPassed.Add((Get-Command -Name $Match -CommandType Function)) | Out-Null

                    $Content += (Get-Command -Name $Match -CommandType Function).ScriptBlock.Ast.Extent.Text

                }
            }
        }
    }

    if ($Content){
        $Content = "#region gfc`n" + $Content + "`n#endregion"
    }

    if($ReturnNames){
        return $FunctionsPassed | Select-Object -Unique # | Where-Object {$_ -notin $Functions} 
    } else {
        return $Content
    }
}
