function Close-Log(){
    [CmdletBinding()]
    param()
    begin{
    }
    process{
        if($null -eq $Script:LogConnection){
            throw "Use `"New-Log`" first, to connect to a logfile!"
            return
        }
        Remove-Variable "LogConnection" -Scope "Script"
    }
    end{}
}