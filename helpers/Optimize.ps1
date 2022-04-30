function Optimize{
    [alias('opt')]
    param(
        $Script,
        [Parameter(ValueFromRemainingArguments = $true)]
        [System.Collections.Arraylist]
        $Arguments
    )
    switch ($Script){
        'OBS'{Invoke-Expression "Optimize-OBS $Arguments"}
        {$_ -in 'OF','Minecraft','Mc','OptiFine'}{Invoke-Expression "Optimize-OptiFine $Arguments"}
        #{$_ -in 'LC','LunarClient'}{Optimize-LunarClient $Arguments}
        #{$_ -in 'Apex','AL','ApexLegends'}{Optimize-ApexLegends $Arguments}
    }
}