function Save-Log(){
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
        if($LogConnection.isEncrypted){
            throw "Use Unprotect-Log first, to edit this logfile!"
            return
        }
        $LogConnection.SaveFile()
    }
    end{}
}