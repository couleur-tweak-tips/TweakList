## PsIni

These functions are from the [PsIni module](https://github.com/lipkau/PsIni), licensed under [MIT](https://github.com/lipkau/PsIni/blob/master/LICENSE)

### Usage

Games like Fortnite and Valorant have these kind of settings file in .INI, they should be a piece of cake to optimize:

```ps
$GUS = Get-IniContent -FilePath "$env:LOCALAPPDATA\VALORANT\Saved\Config\$UserID\Windows\GameUserSettings.ini"
# Do some modifications (eg using Merge-HashTables). . .
Out-IniFile -FilePath "$env:LOCALAPPDATA\VALORANT\Saved\Config\$UserID\Windows\GameUserSettings.ini" -InputObject $GUS
```

