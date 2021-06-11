function Get-Log(){
    [CmdletBinding()]
    param(
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
        return $LogConnection
    }
    end{}
}