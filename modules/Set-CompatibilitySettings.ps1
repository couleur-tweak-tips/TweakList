function Set-CompatibilitySettings {
    [alias('scs')]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Path,

        [Switch]$DisableFullScreenOptimizations,
        [Switch]$RunAsAdmin
    )

    if (!$RunAsAdmin -and !$DisableFullScreenOptimizations){
        return "No compatibility settings were set, returning."
    }

    if ($FilePath.Extension -eq '.lnk'){
        $FilePath = Get-Item (Get-ShortcutTarget $FilePath) -ErrorAction Stop
    }else{
        $FilePath = Get-Item $Path -ErrorAction Stop
    }

    $Data = '~'
    if ($DisableFullScreenOptimizations){$Data += " DISABLEDXMAXIMIZEDWINDOWEDMODE"}
    if ($RunAsAdmin){$Data += " RUNASADMIN"}

    New-ItemProperty -Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" `
    -Name $FilePath.FullName -PropertyType String -Value $Data -Force | Out-Null

}