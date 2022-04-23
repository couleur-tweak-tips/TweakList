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
            $script:Verbose = $True
            $script:VerbosePreference = 'Continue'
        }
        "Disabled" {
            $script:Verbose = $True
            $script:VerbosePreference = 'SilentlyContinue'
        }
    }
}