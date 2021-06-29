function Rename-LogTarget(){
  [CMDLetBinding(PositionalBinding=$false)]
  param(
      [Parameter(Mandatory=$true, Position=0)]
      [GUID]$GUID,

      [Parameter(Mandatory=$true, Position=1)]
      [string]
      $NewName,

      [parameter()]
      [LogFile]
      $LogConnection = $Script:LogConnection
  )
  begin{
  }
  process {
    if($LogConnection -eq $Script:LogConnection){$updateScriptConnection = $true}
      if($null -eq $LogConnection){
          throw "Use `"Open-Log`" first, to connect to a logfile!"
          return
      }
      $target = $LogConnection.Targets |Where-Object -Property GUID -EQ $GUID
      $target.Rename($NewName)
      if($updateScriptConnection){$Script:LogConnection = $LogConnection}
  }
  end{}
}
