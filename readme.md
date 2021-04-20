# Add easy logging to PowerShell

## Installation

1. download the latest release from [git-releases](https://github.com/tim-krehan/powershell-logging/releases)
2. extract the files
3. Open the Powershell in the extracted Folder
4. Install the module with the following command:

``` powershell
Get-Module ".\export\PoShLogging" -ListAvailable |install-module -Scope CurrentUser
```

## Usage

### Open-Log

``` powershell
Open-Log -Name "PowershellLogging" -ShowDebug -LogPath ".\LOG"
```

``` txt
Name         : PowershellLogging
FullName     : C:\Users\tim-krehan\LOG\PowershellLogging.log
Folder       : C:\Users\tim-krehan\LOG
LogLevels    : {DEBUG, INFO, WARNING, SUCCESS...}
LogLines     :
WriteThrough : True
```

### Write-Log

``` powershell
Write-Log INFO information
```

``` txt
2021-01-18 14:38:05.9539 - tim@krehan.de -    INFO - information
```

### Get-Log

``` powershell
Get-Log |Select-Object -ExpandProperty "LogLines"
```

``` txt
DateTime            User Domain       Severity Message
--------            ---- ------       -------- -------    
18.01.2021 14:38:05  tim krehan.de    INFO     information
```

### Clear-Log

clears the current logfile completly

### Close-Log

disconnects from log (can be opend again with ` Open-Log `)
