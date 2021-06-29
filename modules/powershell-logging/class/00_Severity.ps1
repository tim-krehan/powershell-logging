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
