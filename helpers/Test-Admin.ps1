function Test-Admin {

    if (!$IsLinux -and !$IsMacOS){

        $identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal( $identity )
        return $principal.IsInRole( [System.Security.Principal.WindowsBuiltInRole]::Administrator )
    
    }else{ # Running on *nix
        return ((id -u) -eq 0)
    }
}
