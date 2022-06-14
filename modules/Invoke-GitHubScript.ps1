function Invoke-GitHubScript {
    [alias('igs')]
    param(
        [ValidateSet(
            'ChrisTitusTechToolbox',
            'OldChrisTitusTechToolbox',
            'Fido',
            'SophiaScript'
        )]
        $Repository,
        $RawURL
    )
    if ($RawURL){
        Invoke-RestMethod $URL | Invoke-Expression
        return
    }
    function Invoke-URL ($Link) {
        $Response = Invoke-RestMethod $Link
        While ($Response[0] -NotIn '<','#'){ # Byte Order Mark (BOM) removal
            $Response = $Response.Substring(1)
        }
        Invoke-Expression $Response
    }
    switch ($Repository){
        'ChrisTitusTechToolbox'{Invoke-URL https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1}
        'OldChrisTitusTechToolbox'{Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/win10debloat.ps1)}
        'Fido'{Invoke-URL https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1}
        'SophiaScript'{Import-Sophia}
    }
}
