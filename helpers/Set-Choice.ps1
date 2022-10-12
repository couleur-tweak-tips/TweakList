function Set-Choice { # Converts passed string to an array of chars
    param(
        [char[]]$Letters = "YN"
    )
    While ($Key -NotIn $Letters){
        [char]$Key = $host.UI.RawUI.ReadKey([System.Management.Automation.Host.ReadKeyOptions]'NoEcho, IncludeKeyDown').Character
        if (($Key -NotIn $Letters) -and !$IsLinux){
                [Console]::Beep(500,300)
        }
    }
    return $Key
}