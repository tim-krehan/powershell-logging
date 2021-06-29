function Switch-Log(){
  param(
    [parameter(Mandatory=$true)]
    [LogFile]$LogConnection
  )
  begin{}
  process{
    $Script:LogConnection = $LogConnection
    return $Script:LogConnection
  }
  end{}
}
