Class LogTargetStream : LogTarget {
  [string]$GUID
  [LogTargetType]$Type
  [bool]$active = $true
  [Severity[]]$severitiesToDisplay
  LogTargetStream($severitiesToDisplay) : base([LogTargetType]::Console) {
    $this.severitiesToDisplay = $severitiesToDisplay
  }

  Set([LogLine[]]$logLines) {
    $this.checkState()
    $logLines | ForEach-Object -Process {
      $_logLine = $_
      if ($this.severitiesToDisplay.Name -contains $_logLine.Severity.Name) {
        switch ($_logLine.Severity.Name) {
          "DEBUG" {
            Write-Debug -Message $_logLine.Message
            break
          }
          "VERBOSE" {
            Write-Verbose -Message $_logLine.Message
            break
          }
          "INFO" {
            Write-Information -MessageData $_logLine.Message
            break
          }
          "WARNING" {
            Write-Warning -Message $_logLine.Message
            break
          }
          "SUCCESS" {
            Write-Host -Object $_logLine.Message
            break
          }
          "ERROR" {
            Write-Error -Message $_logLine.Message
            break
          }
        }
      }
    }
  }

  [LogLine[]] Get() {
    $this.checkState()
    return @()
  }

  Rename() {
    throw "cannot rename the stream target"
  }
  
  Move() {
    throw "cannot move the stream target"
  }

  Clear() {
    Clear-Host
  }
}
