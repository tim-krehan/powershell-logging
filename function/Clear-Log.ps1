function Clear-Log(){
    param()
    begin{
    }
    process {
        if($null -eq $Script:LogConnection){
            Write-Error "Use `"New-Log`" first, to connect to a logfile!"
            return
        }
        $Script:LogConnection.Clear()
        return Get-Log
    }
    end{}
}