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
function Set-LogConfig(){
    [CMDLetBinding(DefaultParameterSetName="default")]
    param(
        [parameter(parameterSetName="default")]
        [string]
        $Location,

        [parameter(parameterSetName="default")]
        [string]
        $LogName,

        [parameter(ValueFromPipeline=$true,Mandatory=$true,ParameterSetName="pipeline")]
        [PSCustomObject]
        $InputObject
    )
    begin {
        $configFolder =  "$env:APPDATA\b550.log"
        if(!(Test-Path $configFolder)){New-Item -Path $configFolder -ItemType Directory}
        $configFile = "$configFolder\config.json"
        if(!(Test-Path $configFile)){New-Item -Path $configFile -ItemType File -Value "{}"}
        [pscustomobject]$currentConfig = Get-Content $configFile |ConvertFrom-Json
    }
    process{
        if(![string]::IsNullOrEmpty($InputObject)){
            foreach($key in ($InputObject |Get-Member -MemberType NoteProperty |Select-Object -ExpandProperty name)){
                Set-Variable -Name $key -Value $InputObject.$key
            }
        }
        try{
            # set defaultlLocation
            if(![string]::IsNullOrEmpty($Location)){
                if(!(Test-Path $Location)){
                    throw "'$Location' ist nicht vorhanden!"
                }
                $LocationItem = Get-Item $Location
                if($LocationItem.Attributes.toString().Split(",").Trim() -notcontains "Directory"){
                    throw "'$Location' ist kein Ordner!"
                }
                if($null -eq $currentConfig.Location){
                    Add-Member -InputObject $currentConfig -Name "Location" -Value $LocationItem.FullName -MemberType NoteProperty
                }
                else{
                    $currentConfig.Location = $LocationItem.FullName
                }
            }

            # set default name
            if(![string]::IsNullOrEmpty($LogName)){
                if($LogName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -gt 0){
                    throw "'$LogName' enthält ungültige Zeichen!"
                }
                if($null -eq $currentConfig.LogName){
                    Add-Member -InputObject $currentConfig -Name "LogName" -Value $LogName -MemberType NoteProperty
                }
                else{
                    $currentConfig.LogName = $LogName
                }
            }
        }
        catch{
            Write-Error $Error[0].Exception.Message
        }
    }
    end{
        $jsonConfig = $currentConfig |ConvertTo-Json -Depth 100 -Compress:$true
        Out-File -InputObject $jsonConfig -FilePath $configFile -Encoding utf8 -Force
    }
}
function Write-Log(){
    [CMDLetBinding(PositionalBinding=$false)]
    [Alias("ulog")]
    param(
        # severity of logline
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("NOTICE", "INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]
        $severity,

        # actual error text
        [Parameter(Mandatory=$true, Position=1, ValueFromRemainingArguments=$true)]
        [string]
        $logline,

        # logfile location
        [Parameter(Mandatory=$false)]
        [string]
        $logname = "powershell"
    )
    begin{
        $configFile = "$env:APPDATA\b550.log\config.json"
        if(Test-path $configFile){
            $defaultConfig = Get-Content $configFile |ConvertFrom-Json
            if($null -ne $defaultConfig.Location){
                $logfile = $defaultConfig.Location
            }
            else{
                $logfile = "~"
            }
            if($null -ne $defaultConfig.LogName){
                if($null -eq $logname){
                    $logfile += "\" + $defaultConfig.LogName
                }
                else{
                    $logfile += "\$logname"
                }
            }
            else{
                $logfile += "\powershell"
            }
            $logfile += ".log"
        }
        else{
            if([string]::IsNullOrEmpty($logname)){
                $logfile = "~\powershell.log"
            }
            else{
                $logfile = "~\$logname.log"
            }
        }
    }
    process {
        $executionTime = Get-Date -Format "yyyy.MM.dd HH:mm:ss.fff"
        $user = $env:USERNAME
        $domain = $env:USERDNSDOMAIN
        $line = "$executionTime - $($severity.ToUpper().PadLeft(7, " ")) - $($user.ToLower())@$($domain.tolower()) : $logline"
        Out-File -InputObject $line -FilePath $logfile -Encoding utf8 -Append -Width $line.ToCharArray().length -ErrorAction SilentlyContinue
        switch ($severity) {
            "SUCCESS" {
                Write-Host -Object $line -ForegroundColor Green
                break
             }
             "NOTICE" {
                 Write-Host -Object $line -ForegroundColor White
                 break
              }
            "INFO" {
                Write-Host -Object $line -ForegroundColor Cyan
                break
             }
            "WARNING" {
                Write-Host -Object $line -ForegroundColor Yellow
                break
             }
            "ERROR" {
                Write-Host -Object $line -ForegroundColor Red
                break
             }
        }
    }
    end{}
}
