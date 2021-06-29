Class LogTarget {
  [string]$GUID
  [LogTargetType]$Type
  [bool]$Active = $true
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

  hidden checkState(){
    if(!$this.active){
      throw "the target `"$($this.GUID)`" is inactive, please enable it to use it again!"
    }
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
