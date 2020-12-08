function Clear-Log(){
    param()
    begin{
        if($null -eq $Script:LogConnection){
            Write-Error "Use `"New-Log`" first, to connect to a logfile!"
        }
    }
    process {
        [LogBook]$Script:LogConnection.Clear()
        return Get-Log
    }
    end{}
}