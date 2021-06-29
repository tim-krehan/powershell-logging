function Remove-LogTarget() {
  [CmdletBinding(PositionalBinding=$false)]
  param(
    [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
    [GUID]
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
    $Target = $LogConnection.Targets | Where-Object -Property GUID -EQ $GUID
    $LogConnection.RemoveTarget($Target.GUID)
  }
  end {}
}
