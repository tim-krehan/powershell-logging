function Protect-Log(){
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [SecureString]$Password
  )
  begin{
  }
  process{
      if($null -eq $Script:LogConnection){
          throw "Use `"Open-Log`" first, to connect to a logfile!"
          return
      }
      $Script:LogConnection.encrypt($Password)
  }
  end{}
}