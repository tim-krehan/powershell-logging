function Write-Log(){
    [CMDLetBinding(PositionalBinding=$false)]
    [Alias("ulog")]
    param(
        # severity of logline
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("DEBUG", "VERBOSE", "INFO", "WARNING", "SUCCESS", "ERROR")]
        [string]
        $Severity,

        # actual error text
        [Parameter(Mandatory=$true, Position=1, ValueFromRemainingArguments=$true)]
        [string]
        $LogLine,
        
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
        if($LogConnection.isEncrypted){
            throw "Use Unprotect-Log first, to edit this logfile!"
            return
        }
        $LogConnection.AddLine($Severity, $LogLine)
    }
    end{}
}