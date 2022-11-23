Function ConvertTo-VDF
{
<# 
.Synopsis 
    Converts a custom object into a Valve Data File (VDF) formatted string.

.Description 
    The ConvertTo-VDF cmdlet converts any object to a string in Valve Data File (VDF) format. The properties are converted to field names, the field values are converted to property values, and the methods are removed.

.Parameter InputObject
    Specifies PSObject to be converted into VDF strings.  Enter a variable that contains the object. You can also pipe an object to ConvertTo-Json.

.Example 
    ConvertTo-VDF -InputObject $VDFObject | Out-File ".\SharedConfig.vdf"

    Description 
    ----------- 
    Converts the PS object to VDF format and pipes it into "SharedConfig.vdf" in the current directory

.Inputs 
    PSCustomObject

.Outputs 
    System.String


#>
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]
        $InputObject,

        [Parameter(Position=1, Mandatory=$false)]
        [int]
        $Depth = 0
    )
    $output = [string]::Empty
    
    foreach ( $property in ($InputObject.psobject.Properties) ) {
        switch ($property.TypeNameOfValue) {
            "System.String" { 
                $output += ("`t" * $Depth) + "`"" + $property.Name + "`"`t`t`"" + $property.Value + "`"`n"
                break
            }
            "System.Management.Automation.PSCustomObject" {
                $element = $property.Value
                $output += ("`t" * $Depth) + "`"" + $property.Name + "`"`n"
                $output += ("`t" * $Depth) + "{`n"
                $output += ConvertTo-VDF -InputObject $element -Depth ($Depth + 1)
                $output += ("`t" * $Depth) + "}`n"
                break
            }
            Default {
                Write-Error ("Unsupported Property of type {0}" -f $_) -ErrorAction Stop
                break
            }
        }
    }

    return $output
}
