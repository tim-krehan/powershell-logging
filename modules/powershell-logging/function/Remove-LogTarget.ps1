function Remove-LogTarget() {
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
    $LogConnection.RemoveTarget($GUID)
  }
  end {}
}