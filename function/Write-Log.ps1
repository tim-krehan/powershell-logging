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
        $LogLine
    )
    begin{
        if($null -eq $Script:LogConnection){
            Write-Error "Use `"New-Log`" first, to connect to a logfile!"
        }
    }
    process {
        $Script:LogConnection.AddLine($Severity, $LogLine)
    }
    end{}
}