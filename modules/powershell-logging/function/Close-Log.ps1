function Close-Log(){
    [CmdletBinding()]
    param(
        [parameter()]
        [LogFile]
        $LogConnection = $Script:LogConnection
    )
    begin{
    }
    process{
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        $LogConnection.close()
        Remove-Variable "LogConnection" -Scope "Script"
    }
    end{}
}
