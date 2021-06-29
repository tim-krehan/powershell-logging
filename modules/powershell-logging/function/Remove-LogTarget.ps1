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
    if($LogConnection -eq $Script:LogConnection){$updateScriptConnection = $true}
    if ($null -eq $LogConnection) {
      throw "Use `"Open-Log`" first, to connect to a logfile!"
      return
    }
    $LogConnection.RemoveTarget($GUID)
    if($updateScriptConnection){$Script:LogConnection = $LogConnection}
  }
  end {}
}
