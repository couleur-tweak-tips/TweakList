function IsCustomISO {
    switch (
        Get-ItemProperty "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
    ){
        {$_.SupportURL -Like "https://atlasos.net*"}{return 'AtlasOS'}
        {$_.Manufacturer -eq "Revision"}{return 'Revision'}
        {$_.Manufacturer -eq "ggOS"}{return 'ggOS'}
    }
    return $False
}
