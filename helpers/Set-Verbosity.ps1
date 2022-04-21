function Set-Verbosity {
    [alias('Verbose')]
    param (

		[Parameter(Mandatory = $true,ParameterSetName = "Enabled")]
        [switch]$Enabled,

		[Parameter(Mandatory = $true,ParameterSetName = "Disabled")]
		[switch]$Disabled
	)
    
    switch ($PSCmdlet.ParameterSetName){
        "Enabled" {
            $script:VerbosePreference = 'Continue'
        }
        "Disabled" {
            $script:VerbosePreference = 'SilentlyContinue'
        }
    }
}