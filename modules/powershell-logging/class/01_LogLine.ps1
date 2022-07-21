Class LogLine {
  [DateTime]$DateTime
  [string]$User
  [string]$Domain
  [Severity]$Severity
  [String]$Message
  [bool]$Saved = $false

  LogLine($severity, $message, $name) {
    $this.DateTime = Get-Date
    if([string]::isnullorempty($name)){
      if (-not[string]::IsNullOrEmpty($env:USERNAME)) { $this.User = $env:USERNAME.ToLower() }
      elseif (-not[string]::IsNullOrEmpty($env:USER)) { $this.User = $env:USER.ToLower() }
      if (-not[string]::IsNullOrEmpty($env:USERDNSDOMAIN)) { $this.Domain = $env:USERDNSDOMAIN.ToLower() }
      elseif (-not[string]::IsNullOrEmpty($env:COMPUTERNAME)) { $this.Domain = $env:COMPUTERNAME.ToLower() }
      elseif (-not[string]::IsNullOrEmpty($env:NAME)) { $this.Domain = $env:NAME.ToLower() }
      else { $this.Domain = $(hostname).ToLower() }
    }
    else{
      $this.User = $name
      $this.Domain = $null
    }
    $this.Severity = [Severity]::new($severity)
    $this.Message = $message.trim()
  }
  LogLine([string]$line) {
    $lineRegex = [regex]::new("(\d{4}\-\d{2}\-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{4})\s\-\s(.+?)@(.*?)\s\-\s+([A-Z]{1,7})\s\-\s(.+)$")
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
