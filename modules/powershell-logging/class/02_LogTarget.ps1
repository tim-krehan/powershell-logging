Class LogTarget {
  [string]$GUID
  [LogTargetType]$Type
  [bool]$active = $true
  LogTarget([LogTargetType]$type) {
    $this.GUID = [GUID]::NewGuid().GUID.ToUpper()
    $this.Type = $type
  }

  Disable(){
    $this.active = $false
  }

  Enable(){
    $this.active = $true
  }

  Set([LogLine[]]$logLines) {
    throw "not implemented"
  }

  [LogLine[]] Get() {
    throw "not implemented"
  }

  Rename() {
    throw "not implemented"
  }
  
  Move() {
    throw "not implemented"
  }

  Clear() {
    throw "not implemented"
  }

  [String] ToString() {
    return "LogTarget.$($this.Type)"
  }
}
