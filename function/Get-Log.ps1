function Get-Log(){
    [CmdletBinding()]
    param()
    begin{
    }
    process{
        if($null -eq $Script:LogConnection){
            throw "Use `"New-Log`" first, to connect to a logfile!"
            return
        }
        return $Script:LogConnection
    }
    end{}
}