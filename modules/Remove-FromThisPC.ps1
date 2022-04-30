function Remove-FromThisPC {
    param(
        [ValidateSet('Remove','Restore')]
        [String]
        $Action = 'Remove',

        [ValidateSet(
            'Desktop',
            'Documents',
            'Downloads',
            'Music',
            'Pictures',
            'Videos'
            )]
        $Entries,
        [Switch]$All

    )
    if ($All){$Entries = 'Desktop','Documents','Downloads','Music','Pictures','Videos'}
    function Modify-Entry ($GUID){
        if ($Action -eq 'Remove'){
            Remove-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}"
            Remove-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}"    
        }else{
            New-Item -ItemType -Directory -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}" | Out-Null
            New-Item -ItemType -Directory -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}" | Out-Null
        }
        
    }
    ForEach($Entry in $Entries){
        Switch($Entry){
            'Desktop'{
                Modify-Entry B4BFCC3A-DB2C-424C-B029-7FE99A87C641
            }
            'Documents'{
                Modify-Entry A8CDFF1C-4878-43be-B5FD-F8091C1C60D0
                Modify-Entry d3162b92-9365-467a-956b-92703aca08af
            }
            'Downloads'{
                Modify-Entry 374DE290-123F-4565-9164-39C4925E467B
                Modify-Entry 088e3905-0323-4b02-9826-5d99428e115f
            }
            'Music'{
                Modify-Entry 1CF1260C-4DD0-4ebb-811F-33C572699FDE
                Modify-Entry 3dfdf296-dbec-4fb4-81d1-6a3438bcf4de
            }
            'Pictures'{
                Modify-Entry 3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA
                Modify-Entry 24ad3ad4-a569-4530-98e1-ab02f9417aa8
            }
            'Videos'{
                Modify-Entry A0953C92-50DC-43bf-BE83-3742FED03C9C
                Modify-Entry f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a
            }

        }
    }
}