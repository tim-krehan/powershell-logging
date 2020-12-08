function Get-Log(){
    param()
    begin{
        if($null -eq $Script:LogConnection){
            Write-Error "Use `"New-Log`" first, to connect to a logfile!"
        }
    }
    process{
        return $Script:LogConnection
    }
    end{}
}