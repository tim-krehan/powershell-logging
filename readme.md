# Add easy logging to PowerShell!
## Installation
1. download the latest release from [git-releases](https://git.brz.de/powershell-modules/poshlogging/-/releases)
2. extract the files
3. open the PowerShell in the new folder
4. execute the following command:
``` powershell
$source = ".\export\PoShLogging"
$userModulePath = $env:PSModulePath.split(";") |Where-Object -FilterScript {$_ -like "*$env:USERNAME*Windows*PowerShell*"}
Copy-Item -Path $source -Destination $userModulePath -Force -Recurse
```
## Usage
### Write-Log
``` powershell
Write-Log INFO "i am a info logline"
```
```
PS> 2020.12.07 11:58:39.677 -    INFO - steve@contoso.com : i am a informational logline
```
### Get-LogConfig
``` powershell
Get-LogConfig
```
```
PS>

LogName    Location
-------    --------
powershell C:\Users\Steve\Desktop
```
### Set-LogConfig
``` powershell
Set-LogConfig -Location "C:\Users\Steve\Desktop" -LogName "powershell"
```