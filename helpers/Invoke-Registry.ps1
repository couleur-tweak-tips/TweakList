function Invoke-Registry {
    [alias('ireg')]
    param(
        [Parameter(
            Position = 0,
            Mandatory=$true,
            ValueFromPipeline = $true
            )
        ][Array]$Path,

        [Parameter(
            Position = 1,
            Mandatory=$true
            )
        ][HashTable]$HashTable
        
    )

    Process {
        "doing $path"
        $Path = "REGISTRY::$($Path -replace 'REGISTRY::','')"
        "now its $path"
        if (-Not(Test-Path -LiteralPath $Path)){

            New-Item -ItemType Key -Path $Path -Force
        }

        ForEach($Key in $HashTable.Keys){

            Set-ItemProperty -LiteralPath $Path -Name $Key -Value $HashTable.$Key
        }
    }
}
