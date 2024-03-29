Remove-Module powershell-logging -ErrorAction Continue
Import-Module .\build\modules\powershell-logging

# Open Log
$workingDir = "test"
Open-Log -Name PowerShell -LogPath $workingDir

# test the logging to that file
Write-Log DEBUG   "write DEBUG within the current working directory"
Write-Log VERBOSE "write VERBOSE within the current working directory"
Write-Log INFO    "write INFO within the current working directory"
Write-Log SUCCESS "write SUCCESS within the current working directory"
Write-Log WARNING "write WARNING within the current working directory"
Write-Log ERROR   "write ERROR within the current working directory"

# add another Target file
Add-LogTarget -FullName "$workingDir\powershell2.log"
Write-Log DEBUG   "write DEBUG to both logfiles"
Write-Log VERBOSE "write VERBOSE to both logfiles"
Write-Log INFO    "write INFO to both logfiles"
Write-Log SUCCESS "write SUCCESS to both logfiles"
Write-Log WARNING "write WARNING to both logfiles"
Write-Log ERROR   "write ERROR to both logfiles"

# remove all targets, but the additional added target
$log = Get-Log
$obsoleteTarget = $log.Targets[0..1]
$obsoleteTarget.GUID |
  ForEach-Object { Remove-LogTarget -GUID $_ }

# add another Target file
Add-LogTarget -FullName "$workingDir\powershell2.log"
Write-Log DEBUG   "write DEBUG to only the second logfile"
Write-Log VERBOSE "write VERBOSE to only the second logfile"
Write-Log INFO    "write INFO to only the second logfile"
Write-Log SUCCESS "write SUCCESS to only the second logfile"
Write-Log WARNING "write WARNING to only the second logfile"
Write-Log ERROR   "write ERROR to only the second logfile"

# Add the Console again
Add-LogTarget -Console
Close-Log -LogConnection $log

# Open new Stream Only Log
Open-Log -Name StreamLogging -ConsoleType Stream -ShowDebug -ShowVerbose

Write-Log DEBUG   "write DEBUG to stream" -Debug
Write-Log VERBOSE "write VERBOSE to stream" -Verbose
Write-Log INFO    "write INFO to stream" -InformationAction Continue
Write-Log SUCCESS "write SUCCESS to stream"
Write-Log WARNING "write WARNING to stream"
Write-Log ERROR   "write ERROR to stream"

# Open log from pipeline
Get-ChildItem "$workingDir\PowerShell2.log" |
  Open-Log

Get-ChildItem "$workingDir\PowerShell.log" |
  Add-LogTarget

# Clear all log targets from  Pipeline
Get-Log |
  Select-Object -ExpandProperty Targets |
  Where-Object -Property Type -EQ File |
  Clear-LogTarget

Get-Log |
  Select-Object -exp targets


Get-Log |
  Select-Object -exp targets |
  Where-Object type -eq file |
  Where-Object { $_.fileinformation.name -like "powershell.log" } |
  Rename-LogTarget -NewName powershell3.log

Get-ChildItem "$workingDir\PowerShell3.log" |
  Add-LogTarget

Open-Log -Name PowerShell4 -LogPath $workingDir -ShowName
Write-Log DEBUG   "write DEBUG within the current working directory"
Write-Log VERBOSE "write VERBOSE within the current working directory"
Write-Log INFO    "write INFO within the current working directory"
Write-Log SUCCESS "write SUCCESS within the current working directory"
Write-Log WARNING "write WARNING within the current working directory"
Write-Log ERROR   "write ERROR within the current working directory"