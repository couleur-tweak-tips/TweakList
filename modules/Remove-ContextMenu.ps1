<#!TODO:
    Scan windows defender
    Git Bash
    Rotate pictures
    Open with code
    Open with visual studio
    Add to favorites
#>

function Remove-ContextMenu {
    [alias('rcm')]
    <#
    https://www.tenforums.com
    https://winaero.com
    https://majorgeeks.com
    https://github.com/farag2/Sophia-Script-for-Windows
    #>
    param(
        [ValidateSet(
            'PinToQuickAccess',
            'RestorePreviousVersions',
            'Print',
            'GiveAccessTo',
            'EditWithPaint3D',
            'IncludeInLibrary',
            'AddToWindowsMediaPlayerList',
            'CastToDevice',
            'EditWithPaint3D',
            'EditWithPhotos',
            'Share',
            'TakeOwnerShip',
            '7Zip',
            'WinRAR',
            'Notepad++',
            'OpenWithOnBatchFiles',
            'SendTo',
            'DrivesInSendTo',
            'VLC'
            )]
        [Array]$Entries
    )

    $CurrentPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Ignore'
    $Blocked = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"

    if (-Not (Test-Path -Path $Blocked)){
        New-Item -Path $Blocked -Force
    }

    if ('RestorePreviousVersions' -in $Entries){
        New-ItemProperty -Path "$Blocked" -Name "{596AB062-B4D2-4215-9F74-E9109B0A8153}"
    }

    if ('PinToQuickAccess'){
        @('HKEY_CLASSES_ROOT','HKEY_LOCAL_MACHINE\SOFTWARE\Classes') |
        ForEach-Object { Remove-Item "Registry::$_\Folder\shell\pintohome" -Force -Recurse}
    }

    if ('Print' -in $Entries){
        @(
            'SystemFileAssociations\image',
            'batfile','cmdfile','docxfil','fonfile','htmlfil','inffile','inifile','VBSFile','WSFFile',
            'JSEFile','otffile','pfmfile','regfile','rtffile','ttcfile','ttffile','txtfile','VBEFile'
        ) | ForEach-Object {Set-ItemProperty "Registry::HKEY_CLASSES_ROOT\$_\shell\print" -Name "ProgrammaticAccessOnly" -Value ''}
    }

    if ('GiveAccessTo' -in $Entries) {
        @('*','Directory\Background','Directory','Drive','LibraryFolder\background','UserLibraryFolder') |
        ForEach-Object {Remove-Item -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_\shellex\ContextMenuHandlers\Sharing" -Recurse -Force}
    }

    if ('IncludeInLibrary' -in $Entries){
        @('HKEY_LOCAL_MACHINE\SOFTWARE\Classes','HKEY_CLASSES_ROOT') |
        ForEach-Object {Remove-Item "Registry::$_\Folder\ShellEx\ContextMenuHandlers\Library Location" -Force}
    }

    if ('AddToWindowsMediaPlayerList' -in $Entries){
        @(
            '3G2','3GP','ADTS','AIFF','ASF','ASX','AU','AVI','FLAC','M2TS','m3u','M4A','MIDI','MK3D',
            'MKA','MKV','MOV','MP3','MP4','MPEG','TTS','WAV','WAX','WMA','WMV','WPL','WVX'
        ) | ForEach-Object { Remove-Item "Registry::HKEY_CLASSES_ROOT\WMP11.AssocFile.$_\shell\Enqueue" -Force -Recurse }

        @(
            'MediaCenter.WTVFile','Stack.Audio','Stack.Image','SystemFileAssociations\audio','WMP.WTVFile',
            'SystemFileAssociations\Directory.Audio','SystemFileAssociations\Directory.Image','WMP.DVR-MSFile','WMP.DVRMSFile'
        ) | ForEach-Object { Remove-Item "Registry::HKEY_CLASSES_ROOT\$_\shell\Enqueue" -Force -Recurse}
    }

    if ('CastToDevice' -in $Entries){
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" -Name "{7AD84985-87B4-4a16-BE58-8B72A5B390F7}" -PropertyType String -Value "Play to menu" -Force
    }

    if ('EditWithPaint3D' -in $Entries){
        @('.3mf','.bmp','.fbx','.gif','.jfif','.jpe','.jpeg','.jpg','.png','.tif','.tiff') | 
        ForEach-Object { Remove-Item "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\$_\Shell\3D Edit" -Force -Recurse}
    }

    if ('EditWithPhotos' -in $Entries){
        Set-ItemProperty "Registry::HKEY_CLASSES_ROOT\AppX43hnxtbyyps62jhe9sqpdzxn1790zetc\Shell\ShellEdit" -Name 'ProgrammaticAccessOnly' -Value ''
    }

    if ('Share' -in $Entries){
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" -Name "{E2BF9676-5F8F-435C-97EB-11607A5BEDF7}" -PropertyType String -Value "" -Force
    }

    if ('TakeOwnerShip' -in $Entries){
        @(
        'HKEY_CLASSES_ROOT\*\shell\runas'
        'HKEY_CLASSES_ROOT\Directory\shell\runas'
        'HKEY_CLASSES_ROOT\*\shell\TakeOwnership'
        'HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership'
        'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\*\shell\TakeOwnership'
        'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\*\shell\TakeOwnership'
        'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Directory\shell\TakeOwnership'
        ) | ForEach-Object {
            Remove-Item -LiteralPath "Registry::$_" -Recurse -Force
        }
    }

    if ('SendTo' -in $Entries){
        $DefaultSendTo = (
        'Bluetooth File Transfer',
        'Compressed (zipped) Folder',
        'Desktop (create shortcut)',
        'Documents',
        'Fax Recipient',
        'Mail Recipient'
        )
        $NonDefaultSendTo = Get-ChildItem ([System.Environment]::GetFolderPath('SendTo')) | Where-Object BaseName -NotIn $DefaultSendTo
        if ($NonDefaultSendTo) {
            $NonDefaultSendTo.Name
            if(Get-Boolean "Are you sure you wish to lose access the following files/scripts?"){
                New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo -Name "(default)" -PropertyType String -Value "-{7BA4C740-9E81-11CF-99D3-00AA004AE837}" -Force
            }
        }else{
            New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo -Name "(default)" -PropertyType String -Value "-{7BA4C740-9E81-11CF-99D3-00AA004AE837}" -Force
        }
    }

    if ('DrivesInSendTo' -in $Entries){
        Set-ItemProperty "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoDrivesInSendToMenu -Value 1
    }
    
    if ('OpenWithOnBatchFiles' -in $Entries){
        foreach ($Ext in 'bat','cmd'){
            Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\$($Ext)file\shell\Open with\command" -Force -Recurse
        }
    }

    if ('7Zip' -in $Entries){
        @(
            'Classes\CLSID\{23170F69-40C1-278A-1000-000100020000}',
            'Classes\CLSID\{23170F69-40C1-278A-1000-000100020000}\InprocServer32',
            'Classes\*\shellex\ContextMenuHandlers\7-Zip',
            'Classes\Directory\shellex\ContextMenuHandlers\7-Zip',
            'Classes\Folder\shellex\ContextMenuHandlers\7-Zip',
            '7-Zip\Options'
        ) | ForEach-Object {Remove-Item -LiteralPath "REGISTRY::HKEY_CURRENT_USER\Software\$_" -Recurse -Force}
    }
    
    if ('WinRAR' -in $Entries){ # This hides (adds to Blocked) instead of deleting
        @('{B41DB860-64E4-11D2-9906-E49FADC173CA}','{B41DB860-8EE4-11D2-9906-E49FADC173CA}') |
        ForEach-Object {New-ItemProperty -Path $Blocked -Name $_ -Value ''}
    }

    if ('Notepad++' -in $Entries){
        @(
            '*\shell\Open with &Notepad++',
            '*\shell\Open with &Notepad++\command',
            'Directory\shell\Open with &Notepad++',
            'Directory\shell\Open with &Notepad++\command',
            'Directory\Background\shell\Open with &Notepad++',
            'Directory\Background\shell\Open with &Notepad++\command'
        ) | ForEach-Object {
            Remove-Item -LiteralPath "Registry::HKEY_CURRENT_USER\Software\Classes\$_" -Recurse -Force
        }

    }

    if ('VLC' -in $Entries){

        @(
            'Directory\shell\PlayWithVLC'
            'Directory\shell\AddtoPlaylistVLC'
            
        ) | ForEach-Object {
            if (Test-Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\$_"){
                Remove-Item -LiteralPath "Registry::HKEY_CLASSES_ROOT\Directory\shell\$PSItem" -Recurse -Force
            }
        }
        ForEach($Context in ('PlayWithVLC','AddtoPlaylistVLC')){
            @(
                '3g2', '3ga', '3gp', '3gp2', '3gpp', '669', 'a52', 'aac', 'ac3', 'adt', 'adts', 'aif', 'aifc', 'aiff',
                'amr', 'amv', 'aob', 'ape', 'asf', 'asx', 'au', 'avi', 'b4s', 'bik', 'Bluray', 'caf', 'cda', 'CDAudio',
                'cue', 'dav', 'divx', 'drc', 'dts', 'dv', 'DVDMovie', 'dvr-ms', 'evo', 'f4v', 'flac', 'flv', 'gvi', 'gxf',
                'ifo', 'iso', 'it', 'm1v', 'm2t', 'm2ts', 'm2v', 'm3u', 'm3u8', 'm4a', 'm4p', 'm4v', 'mid', 'mka', 'mkv',
                'mlp', 'mod', 'mov', 'mp1', 'mp2', 'mp2v', 'mp3', 'mp4', 'mp4v', 'mpa', 'mpc', 'mpe', 'mpeg', 'mpeg1',
                'mpeg2', 'mpeg4', 'mpg', 'mpga', 'mpv2', 'mts', 'mtv', 'mxf', 'nsv', 'nuv', 'oga', 'ogg', 'ogm', 'ogv',
                'ogx', 'oma', 'OPENFolder', 'opus', 'pls', 'qcp', 'ra', 'ram', 'rar', 'rec', 'rm', 'rmi', 'rmvb', 'rpl',
                's3m', 'sdp', 'snd', 'spx', 'SVCDMovie', 'thp', 'tod', 'tp', 'ts', 'tta', 'tts', 'VCDMovie', 'vlc', 'vlt',
                'vob', 'voc', 'vqf', 'vro', 'w64', 'wav', 'webm', 'wma', 'wmv', 'wpl', 'wsz', 'wtv', 'wv', 'wvx', 'xa', 'xesc',
                'xm', 'xspf', 'zip', 'zpl','3g2','3ga','3gp','3gp2','3gpp'

            ) | ForEach-Object {
                $Key = "Registry::HKEY_CLASSES_ROOT\VLC.$PSItem\shell\$Context"
                if (Test-Path $Key){
                    Remove-Item -LiteralPath $Key -Recurse -Force
                }
            }
        }
    }
    
    $ErrorActionPreference = $CurrentPreference
}
