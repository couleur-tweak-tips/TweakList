
function Get-ScoopApp {
    [CmdletBinding()] param (

        [Parameter(ValueFromRemainingArguments = $true)]
        [System.Collections.Arraylist]
        $Apps # Not necessarily plural
    )

    Install-Scoop

    $Scoop = (Get-Item (Get-Command scoop).Source).Directory | Split-Path
    $ToInstall = $Apps | Where-Object {$PSItem -NotIn (Get-ChildItem "$Scoop\apps")}
    $Available = (Get-ChildItem "$Scoop\buckets\*\bucket\*").BaseName
    $Buckets = (Get-ChildItem "$Scoop\buckets" -Directory).Name
    $script:FailedToInstall = @()

    function Get-Git {
        if ('git' -NotIn $Available){
            scoop install git
            if ($LASTEXITCODE -ne 0){
                Write-Host "Failed to install Git." -ForegroundColor Red
                return
            }
        }
        $ToInstall = $ToInstall | Where-Object {$_ -ne 'git'}
    }

    $Repos = @{

        extras = @{org = 'ScoopInstaller';repo = 'extras';branch = 'master'}
        utils = @{org = 'couleur-tweak-tips';repo = 'utils';branch = 'main'}
        nirsoft = @{org = 'kodybrown';repo = 'scoop-nirsoft';branch = 'master'}
        games = @{org = 'ScoopInstaller';repo = 'games';branch = 'master'}
        'nerd-fonts' = @{org = 'ScoopInstaller';repo = 'nerd-fonts';branch = 'master'}
        versions = @{org = 'ScoopInstaller';repo = 'versions';branch = 'master'}
        java = @{org = 'ScoopInstaller';repo = 'java';branch = 'master'}
    }
    $RepoNames = $Repos.Keys -Split('\r?\n')

    Foreach($App in $ToInstall){

        if ($App.Split('/').Count -eq 2){

            $Bucket, $App = $App.Split('/')

            if ($Bucket -NotIn $RepoNames){
                Write-Host "Bucket $Bucket is not known, add it yourself by typing 'scoop.cmd bucket add bucketname https://bucket.repo/url'"
                continue
            }elseif (($Bucket -NotIn $Buckets) -And ($Bucket -In $RepoNames)){
                Get-Git
                scoop bucket add $Repos.$Bucket.repo https://github.com/$($Repos.$Bucket.org)/$($Repos.$Bucket.repo)
            }
        }

        $Available = (Get-ChildItem "$Scoop\buckets\*\bucket\*").BaseName

        if ($App -NotIn $Available){
            Remove-Variable -Name Found -ErrorAction Ignore
            ForEach($Bucket in $RepoNames){
                if ($Found){continue}

                Write-Host "`rCould not find $App, looking for it in the $Bucket bucket.." -NoNewline

                $Response = Invoke-RestMethod "https://api.github.com/repos/$($Repos.$Bucket.org)/$($Repos.$Bucket.repo)/git/trees//$($Repos.$Bucket.branch)?recursive=1"
                $Manifests = $Response.tree.path | Where-Object {$_ -Like "bucket/*.json"}
                $Manifests = ($Manifests).Replace('bucket/','').Replace('.json','')

                if ($App -in $Manifests){
                    $script:Found = $True
                    ''
                    Get-Git
                    
                    scoop bucket add $Repos.$Bucket.repo https://github.com/$($Repos.$Bucket.org)/$($Repos.$Bucket.repo)
                }else{''} # Fixes the -NoNewLine
            }
            
        }
        scoop install $App
        if ($LASTEXITCODE -ne 0){
            $script:FailedToInstall += $App
            Write-Verbose "$App exitted with code $LASTEXITCODE"        
        }
    }

}