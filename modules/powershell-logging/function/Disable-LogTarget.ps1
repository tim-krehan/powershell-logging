function Disable-LogTarget() {
  [CMDLetBinding(PositionalBinding = $false)]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $GUID,

    [parameter()]
    [LogFile]
    $LogConnection = $Script:LogConnection
  )
  begin {
  }
  process {
    if ($null -eq $LogConnection) {
      throw "Use `"Open-Log`" first, to connect to a logfile!"
      return
    }

    $target = $LogConnection.Targets |Where-Object -Property GUID -EQ $GUID
    $target.Disable()
  }
  end {}
}
