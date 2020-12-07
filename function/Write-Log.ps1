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