Function ConvertFrom-VDF {
<# 
.Synopsis 
    Reads a Valve Data File (VDF) formatted string into a custom object.

.Description 
    The ConvertFrom-VDF cmdlet converts a VDF-formatted string to a custom object (PSCustomObject) that has a property for each field in the VDF string. VDF is used as a textual data format for Valve software applications, such as Steam.

.Parameter InputObject
    Specifies the VDF strings to convert to PSObjects. Enter a variable that contains the string, or type a command or expression that gets the string. 

.Example 
    $vdf = ConvertFrom-VDF -InputObject (Get-Content ".\SharedConfig.vdf")

    Description 
    ----------- 
    Gets the content of a VDF file named "SharedConfig.vdf" in the current location and converts it to a PSObject named $vdf

.Inputs 
    System.String

.Outputs 
    PSCustomObject


#>
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [AllowEmptyString()]
        [String[]]
        $InputObject
    )

    $root = New-Object -TypeName PSObject
    $chain = [ordered]@{}
    $depth = 0
    $parent = $root
    $element = $null

    #Magic PowerShell Switch Enumrates Arrays
    switch -Regex ($InputObject) {
        #Case: ValueKey
        '^\t*"(\S+)"\t\t"(.+)"$' {
            Add-Member -InputObject $element -MemberType NoteProperty -Name $Matches[1] -Value $Matches[2]
            continue
        }
        #Case: ParentKey
        '^\t*"(\S+)"$' { 
            $element = New-Object -TypeName PSObject
            Add-Member -InputObject $parent -MemberType NoteProperty -Name $Matches[1] -Value $element
            continue
        }
        #Case: Opening ParentKey Scope
        '^\t*{$' {
            $parent = $element
            $chain.Add($depth, $element)
            $depth++
            continue
        }
        #Case: Closing ParentKey Scope
        '^\t*}$' {
            $depth--
            $parent = $chain.($depth - 1)
            $element = $parent
            $chain.Remove($depth)
            continue
        }
        #Case: Comments or unsupported lines
        Default {
            Write-Debug "Ignored line: $_"
            continue
        }
    }

    return $root
}
