function Unprotect-Log(){
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [SecureString]$Password,

    [parameter()]
    [LogFile]
    $LogConnection = $Script:LogConnection
  )
  begin{
  }
  process{
      if($null -eq $LogConnection){
          throw "Use `"Open-Log`" first, to connect to a logfile!"
          return
      }
      $LogConnection.decrypt($Password)
  }
  end{}
}