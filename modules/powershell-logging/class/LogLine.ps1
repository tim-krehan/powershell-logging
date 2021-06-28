Enum LogTargetType{
  File
  Console
  System
  None
}
Class Severity {
  $Name
  $Color
  Severity($name) {
    switch ($name) {
      "DEBUG" {
        $this.Color = [System.ConsoleColor]::DarkBlue
        $this.Name = "DEBUG"
        break
      }
      "VERBOSE" {
        $this.Color = [System.ConsoleColor]::DarkYellow
        $this.Name = "VERBOSE"
        break
      }
      "INFO" {
        $this.Color = [System.ConsoleColor]::White
        $this.Name = "INFO"
        break
      }
      "WARNING" {
        $this.Color = [System.ConsoleColor]::Yellow
        $this.Name = "WARNING"
        break
      }
      "SUCCESS" {
        $this.Color = [System.ConsoleColor]::Green
        $this.Name = "SUCCESS"
        break
      }
      "ERROR" {
        $this.Color = [System.ConsoleColor]::Red
        $this.Name = "ERROR"
        break
      }
      default {
        break
      }
    }
  }
  [string] ToString() {
    return $this.Name
  }
}
Class LogLine {
  [DateTime]$DateTime
  [string]$User
  [string]$Domain
  [Severity]$Severity
  [String]$Message
  [bool]$Saved = $false

  LogLine($severity, $message) {
    $this.DateTime = Get-Date
    if (-not[string]::IsNullOrEmpty($env:USERNAME)) { $this.User = $env:USERNAME.ToLower() }
    elseif (-not[string]::IsNullOrEmpty($env:USER)) { $this.User = $env:USER.ToLower() }
    if (-not[string]::IsNullOrEmpty($env:USERDNSDOMAIN)) { $this.Domain = $env:USERDNSDOMAIN.ToLower() }
    elseif (-not[string]::IsNullOrEmpty($env:COMPUTERNAME)) { $this.Domain = $env:COMPUTERNAME.ToLower() }
    elseif (-not[string]::IsNullOrEmpty($env:NAME)) { $this.Domain = $env:NAME.ToLower() }
    else { $this.Domain = $(hostname).ToLower() }
    $this.Severity = [Severity]::new($severity)
    $this.Message = $message.trim()
  }
  LogLine([string]$line) {
    $lineRegex = [regex]::new("(\d{4}\-\d{2}\-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{4})\s\-\s(.+?)@(.+?)\s\-\s+([A-Z]{1,7})\s\-\s(.+)$")
    $match = $lineRegex.Match($line)
    if ($match.Success) {
      $this.DateTime = Get-Date $match.Groups[1].Value
      $this.User = $match.Groups[2].Value
      $this.Domain = $match.Groups[3].Value
      $this.Severity = [Severity]::new($match.Groups[4].Value)
      $this.Message = $match.Groups[5].Value.trim()
    }
    else {
      Write-Warning "Skipping Line (Format not recognized)$([Environment]::NewLine)`t`"$line`""
    }
  }
  [string] ToString() {
    return "{0} - {1}@{2} - {3} - {4}" -f @(
      (Get-Date $this.DateTime -Format "yyyy-MM-dd HH:mm:ss.ffff")
      $this.User
      $this.Domain
      $this.Severity.Name.padLeft(7, " ")
      $this.Message
    )
  }
}
Class LogTarget {
  [string]$GUID
  [LogTargetType]$Type
  [bool]$active = $true
  LogTarget([LogTargetType]$type) {
    $this.GUID = [GUID]::NewGuid().GUID.ToUpper()
    $this.Type = $type
  }

  Set([LogLine[]]$logLines) {
    throw "not implemented"
  }

  [LogLine[]] Get() {
    throw "not implemented"
  }

  [String] ToString() {
    return "LogTarget.$($this.Type)"
  }
}
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
Class LogTargetFile : LogTarget {
  [System.IO.FileSystemInfo]$fileInformation
  LogTargetFile($filePath) : base([LogTargetType]::File) {
    try {
      $this.fileInformation = Get-Item -Path $filePath
    }
    catch {
      $this.fileInformation = New-Item -Path $filePath -ItemType File -Force
    }
  }

  Set([LogLine[]]$logLines) {
    $newContent = $logLines | ForEach-Object -Process { $_.ToString() }
    $joinedContent = $newContent -join [Environment]::NewLine
    try {
      Out-File -InputObject $joinedContent -Append -FilePath $this.fileInformation.FullName -Encoding utf8
    }
    catch {
      throw "Error Saving File"
    }
  }

  [LogLine[]] Get() {
    $availableContent = (Get-Content -Encoding UTF8 -Path $this.fileInformation.FullName) -split [Environment]::NewLine
    $returnedLines = @()
    foreach ($line in $availableContent) {
      $newline = [LogLine]::new($line)
      $newline.Saved = $true
      $returnedLines += $newline
    }
    return $returnedLines
  }

  Move($newLocation) {
    if (Test-Path -Path $newLocation) {
      $newLocationItem = Get-Item -Path $newLocation
      if ($newLocationItem -is [System.IO.DirectoryInfo]) {
        $dest = Move-Item -Path $this.fileInformation.FullName -Destination $newLocation -PassThru
        $this.fileInformation = $dest
      }
      else {
        throw "destination needs to be a folder"
      }
    }
    else {
      throw "folder '$newLocation' not existant"
    }
  }

  Rename($newName) {
    $dest = Rename-Item -Path $this.fileInformation.FullName -NewName $newName -PassThru
    $this.fileInformation = $dest
  }
}

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