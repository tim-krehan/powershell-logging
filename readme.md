# Add easy logging to PowerShell

[![Publish to Gallery](https://github.com/tim-krehan/powershell-logging/actions/workflows/main.yml/badge.svg)](https://github.com/tim-krehan/powershell-logging/actions/workflows/main.yml)

## Installation

Just install the modul from the [Powershell Gallery](https://www.powershellgallery.com/packages/powershell-logging)

``` powershell
Install-Module -Name powershell-logging -Repository PSGallery -Scope CurrentUser
```

## Usage

### Open-Log

``` powershell
# Open (or switch to) a new log file with console and file target.
$LogConnection = Open-Log -Name "PowershellLogging" -LogPath ".\LOG"
# Open an existing logfile
$LogConnection = Get-ChildItem ".\Log\PowershellLogging.log" | Open-Log
# Open a log, that writes exclusivly to the console
Open-Log -Name "PowershellLogging"
# Open a log, that uses the Powershell Streams to write the corresponding messages to
Open-Log -Name "PowershellLogging" -ConsoleType "Stream"
```

``` txt
 Name            Active                Targets LogLines
 ----            ------                ------- --------
 PowerShell.log    True        {Console, File} -
```

### Write-Log

``` powershell
# Write a new informative line to the currently opened log.
Write-Log INFO information
# Write a new error line to the given log connection.
Write-Log ERROR error -LogConnection $LogConnection
```

``` txt
2021-01-18 14:38:05.9539 - tim@krehan.de -    INFO - information
2021-01-18 14:39:05.0000 - tim@krehan.de -   ERROR - error
```

### Get-Log

``` powershell
# Gets the currently active log connection
Get-Log
```

``` txt
 Name                                   LogLevels WriteThrough LogLines
 ----                                   --------- ------------ --------
 PowershellLogging {INFO, WARNING, SUCCESS, ERROR}         True -
```

### Close-Log

``` powershell
# closes the currently opened log
Close-Log
# closes the given log connection
Close-Log -LogConnection $LogConnection
```

### Get-LogContent

``` powershell
# selects the first two ERRORS within the current log file
Get-LogContent -First 2 -IncludeError
# selects the last 10 Entries within the given log connection
Get-LogContent -Last 10 -LogConnection $LogConnection
# selects the last 10 Entries that match with the given string of the given log file
Get-LogContent -Last 10 -LogConnection $LogConnection -Filter "iis"
```

``` txt
DateTime            User Domain       Severity Message
--------            ---- ------       -------- -------
11.06.2021 08:37:22  tim krehan.de       ERROR error
11.06.2021 09:40:27  tim krehan.de       ERROR error2
```

```txt
DateTime            User Domain    Severity Message
--------            ---- ------    -------- -------
11.06.2021 08:37:17  tim krehan.de     INFO info
11.06.2021 08:37:18  tim krehan.de     INFO info
11.06.2021 08:37:19  tim krehan.de     INFO info
11.06.2021 08:37:20  tim krehan.de    ERROR error
11.06.2021 08:37:21  tim krehan.de     INFO info
11.06.2021 08:37:22  tim krehan.de     INFO info
11.06.2021 08:37:23  tim krehan.de     INFO info
11.06.2021 08:37:24  tim krehan.de     INFO info
11.06.2021 08:37:25  tim krehan.de    ERROR error
11.06.2021 08:37:26  tim krehan.de     INFO info
```

```txt
DateTime            User Domain    Severity Message
--------            ---- ------    -------- -------
11.06.2021 08:37:17  tim krehan.de     INFO iis started up
11.06.2021 08:37:18  tim krehan.de    ERROR iis failed to start!
11.06.2021 08:37:19  tim krehan.de     INFO web server (iis) has exited
```

### Add-LogTarget

``` powershell
# Add Another Target to the currently opened log
Add-LogTarget -FullName ".\LOG\PowershellLogging2.log"
```

```txt
 Name       Active               Targets LogLines
 ----       ------               ------- --------
 PowerShell   True {Console, File, File} -
```

### Remove-LogTarget

``` powershell
# Removes the second LogTarget
Remove-LogTarget -GUID ((Get-Log).Targets[1].GUID)
# Removes all LogTargets
Get-Log |Select-Object -ExpandProperty Targets | Remove-LogTarget
```

### Clear-LogTarget

``` powershell
# Clears the second LogTarget
Clear-LogTarget -GUID ((Get-Log).Targets[1].GUID)
# Clears all LogTargets
Get-Log |Select-Object -ExpandProperty Targets | Clear-LogTarget
# a target of type Console will delete all scrolling history, a file type will remove all file content.
```

### Move-LogTarget

``` powershell
# Moves the target to the specified destination
Move-LogTarget -Path "C:\Log" -GUID "F421DC01-0275-4EB8-BE78-7D9E4966E999"
# Moves the given log file to the specified destination
(Get-Log).Targets |where-object Type -like File |Foreach-Object -Process {
    Move-LogTarget -Target $_ -Path ".\LOG2"
}
```

### Rename-LogTarget

``` powershell
# Renames the target
Rename-LogTarget -NewName "powershell" -GUID "F421DC01-0275-4EB8-BE78-7D9E4966E999"
```

### Switch-Log

``` powershell
# Sets the given log as new active log conneciton
Switch-Log -LogConnection $LogConnection
```

```txt
     Name                       LogLevels WriteThrough LogLines
     ----                       --------- ------------ --------
 log2.log {INFO, WARNING, SUCCESS, ERROR}         True 12x INFO; 3x ERROR
```