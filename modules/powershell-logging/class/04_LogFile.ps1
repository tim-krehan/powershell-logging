Class LogFile {
  [string]$Name
  [array]$LogLines
  [bool]$Active
  [bool]$ShowName
  [LogTarget[]]$Targets

  LogFile($name) {
    $this.Name = $name
    $this.Active = $true
  }

  [LogTarget] AddTarget([LogTargetType]$targetType = [LogTargetType]::File, $targetArguments) {
    $newTaget = New-Object -TypeName "LogTarget$targetType" -ArgumentList @($targetArguments.Values)
    $this.Targets += $newTaget
    if ($newTaget | Get-Member -MemberType Method -Name Get) {
      $this.LogLines += $newTaget.Get()
      $this.LogLines = $this.LogLines | Sort-Object -Property DateTime -Unique
    }
    return $newTaget
  }

  RemoveTarget([GUID]$GUID) {
    $newTargets = $this.Targets | Where-Object -Property GUID -NE $GUID.Guid
    $this.Targets = $newTargets
  }

  AddLine($severity, $message) {
    $logName = $null
    if (!$this.Active) { throw "Log '$($this.Name)' is inactive! Open it again to use it." }
    if($this.ShowName){
      $logName = $this.Name
    }
    $logline = [LogLine]::new($severity, $message, $logName)
    $this.LogLines += $logline
    $this.Targets |Where-Object -Property Active -EQ -Value $true | ForEach-Object -Process {
      if ($null -eq $_) { continue }
      $_.Set($logline);
    }
  }

  Close() {
    if (!$this.active) { throw "Log '$($this.Name)' is inactive! Open it again to use it." }
    $this.active = $false
  }
}
