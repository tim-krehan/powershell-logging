function Rename-Log(){
  [CMDLetBinding(PositionalBinding=$false)]
  param(
      # new directory
      [Parameter(Mandatory=$true, Position=0)]
      [string]
      $NewName,

      [parameter()]
      [LogFile]
      $LogConnection = $Script:LogConnection
  )
  begin{
    if($null -ne $LogConnection){  
        Switch-ActiveLog -LogConnection $LogConnection
    }
  }
  process {
      if($null -eq $Script:LogConnection){
          throw "Use `"Open-Log`" first, to connect to a logfile!"
          return
      }
      $Script:LogConnection.Rename($NewName)
  }
  end{}
}