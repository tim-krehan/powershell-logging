Class LogTargetConsole : LogTarget {
  [string]$GUID
  [LogTargetType]$Type
  [bool]$active = $true
  [Severity[]]$severitiesToDisplay
  LogTargetConsole($severitiesToDisplay) : base([LogTargetType]::Console) {
    $this.severitiesToDisplay = $severitiesToDisplay
  }

  Set([LogLine[]]$logLines) {
    $logLines | ForEach-Object -Process {
      $_logLine = $_
      if ($this.severitiesToDisplay.Name -contains $_logLine.Severity.Name) {
        Write-Host -Object $logline.ToString() -ForegroundColor $logline.Severity.Color
      }
    }
  }

  [LogLine[]] Get() {
    return @()
  }
}
