function Get-LogConfig(){
    param()
    begin {
        $configFolder =  "$env:APPDATA\b550.log"
        if(!(Test-Path $configFolder)){New-Item -Path $configFolder -ItemType Directory}
        $configFile = "$configFolder\config.json"
        if(!(Test-Path $configFile)){New-Item -Path $configFile -ItemType File -Value "{}" |Out-Null}
        [pscustomobject]$currentConfig = Get-Content $configFile |ConvertFrom-Json
    }
    process{
        return $currentConfig
    }
    end{

    }
}