function Switch-ActiveLog(){
  param(
    [parameter(Mandatory=$true)]
    [LogFile]$LogConnection
  )
  begin{}
  process{
    $Script:LogConnection = $LogConnection
  }
  end{}
}