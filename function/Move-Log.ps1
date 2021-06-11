function Move-Log(){
  [CMDLetBinding(PositionalBinding=$false)]
  param(
      # new directory
      [Parameter(Mandatory=$true, Position=0)]
      [string]
      $Path,

      [parameter()]
      [LogFile]
      $LogConnection = $Script:LogConnection
  )
  begin{
  }
  process {
      if($null -eq $LogConnection){
          throw "Use `"Open-Log`" first, to connect to a logfile!"
          return
      }
      $LogConnection.Move($Path)
  }
  end{}
}