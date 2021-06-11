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
    if($null -ne $LogConnection){  
        Switch-ActiveLog -LogConnection $LogConnection
    }
  }
  process{
      if($null -eq $Script:LogConnection){
          throw "Use `"Open-Log`" first, to connect to a logfile!"
          return
      }
      $Script:LogConnection.decrypt($Password)
  }
  end{}
}