Class LogFile {
  [string]$Name
  [array]$LogLines
  [bool]$Active
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
      $this.LogLines = $this.LogLines | Sort-Object -Property DateTime
    }
    return $newTaget
  }

  RemoveTarget($GUID) {
    $newTargets = $this.Targets | Where-Object -Property GUID -NE $GUID
    $this.Targets = $newTargets
  }

  AddLine($severity, $message) {
    if (!$this.active) { throw "Log '$($this.Name)' is inactive! Open it again to use it." }
    $logline = [LogLine]::new($severity, $message)
    $this.LogLines += $logline
    $this.Targets | ForEach-Object -Process {
      if ($null -eq $_) { continue }
      $_.Set($logline);
    }
  }

  # Clear() {
  #     if (!$this.active) { throw "Log '$($this.Name)' is inactive! Open it again to use it." }
  #     $this.LogLines = @()
  #     New-Item -Path $this.FullName -ItemType File -Force
  # }

  Close() {
    if (!$this.active) { throw "Log '$($this.Name)' is inactive! Open it again to use it." }
    $this.active = $false
  }
}
