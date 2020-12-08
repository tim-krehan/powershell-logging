function Get-Log(){
    param()
    begin{
    }
    process{
        if($null -eq $Script:LogConnection){
            Write-Error "Use `"New-Log`" first, to connect to a logfile!"
            return
        }
        return $Script:LogConnection
    }
    end{}
}