function Clear-LogTarget(){
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName="GUID")]
    param(
        [Parameter(ParameterSetName="GUID",ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [GUID]
        $GUID,
        
        [Parameter(ParameterSetName="pipeline",ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [LogTarget[]]
        $Targets,
        
        [parameter(ValueFromPipeline = $false)]
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
        
        if($PsCmdlet.ParameterSetName -eq "GUID"){
            $Targets = $LogConnection.Targets |Where-Object -Property GUID -EQ $GUID
        }
        $Targets |ForEach-Object -Process {$_.Clear()}
        
    }
    end{}
}
