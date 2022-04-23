function Get-Path {
    [alias('gpa')]
    param($File)

    if (-Not(Get-Command $File -ErrorAction Ignore)){return $null}

    $BaseName, $Extension = $File.Split('.')

    if (Get-Command "$BaseName.shim" -ErrorAction Ignore){
        return (Get-Content (Get-Command "$BaseName.shim").Source | Select-Object -First 1).Trim('path = ')
    }elseif($Extension){
        return (Get-Command "$BaseName.$Extension").Source
    }else{
        return (Get-Command $BaseName).Source
    }
}