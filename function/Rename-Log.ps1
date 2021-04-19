function Rename-Log(){
  [CMDLetBinding(PositionalBinding=$false)]
  param(
      # new directory
      [Parameter(Mandatory=$true, Position=0)]
      [string]
      $NewName
  )
  begin{
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