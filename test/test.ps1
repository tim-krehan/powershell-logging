Remove-Module powershell-logging -ErrorAction Continue
Import-Module .\build\modules\powershell-logging

# Open Log
$workingDir = "test"
$log = Open-Log -Name PowerShell -LogPath $workingDir

# test the logging to that file
Write-Log DEBUG   "write DEBUG within the current working directory"
Write-Log VERBOSE "write VERBOSE within the current working directory"
Write-Log INFO    "write INFO within the current working directory"
Write-Log WARNING "write WARNING within the current working directory"
Write-Log ERROR   "write ERROR within the current working directory"

# add another Target file
$target = Add-LogTarget -FullName "$workingDir\powershell2.log" -LogConnection $log
Write-Log DEBUG   "write DEBUG to both logfiles"
Write-Log VERBOSE "write VERBOSE to both logfiles"
Write-Log INFO    "write INFO to both logfiles"
Write-Log WARNING "write WARNING to both logfiles"
Write-Log ERROR   "write ERROR to both logfiles"

#remove all targets, but the additional added target
$log = Get-Log
$obsoleteTarget = $log.Targets |Where-Object -Property GUID -NE -Value $target.GUID
Remove-LogTarget -GUID $obsoleteTarget.GUID
# # Write-Log INFO "log 1"

# remove-logtarget -guid $_.GUID
# Write-Log INFO "logzeile in log nummer 2"
