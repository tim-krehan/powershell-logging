function Clear-Log(){
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [GUID]
        $LogTartet = ($Script:LogConnection.Targets |Where-Object Type -EQ File |Select-Object -First 1 -ExpandProperty GUID),
        
        [parameter()]
        [LogFile]
        $LogConnection = $Script:LogConnection
    )
    begin{
    }
    process {
        if($null -eq $LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        $target = $LogConnection.Targets |Where-Object -Property GUID -EQ $GUID
        $target.Clear()
    }
    end{}
}
