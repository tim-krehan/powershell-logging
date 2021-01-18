function Clear-Log(){
    [CmdletBinding()]
    param()
    begin{
    }
    process {
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        $Script:LogConnection.Clear()
    }
    end{}
}