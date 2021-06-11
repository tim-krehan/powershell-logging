function Get-LogContent(){
    [CmdletBinding(DefaultParameterSetName="__default")]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string]
        $Filter,

        [int32]
        [Parameter(ParameterSetName="First")]
        $First,

        [int32]
        [Parameter(ParameterSetName="Last")]
        $Last,

        [switch]
        $IncludeDebug,

        [switch]
        $IncludeVerbose,

        [switch]
        $IncludeInfo,

        [switch]
        $IncludeWarning,

        [switch]
        $IncludeSuccess,

        [switch]
        $IncludeError,

        [parameter()]
        [LogFile]
        $LogConnection = $Script:LogConnection
    )
    begin{
        if($null -ne $LogConnection){  
            Switch-ActiveLog -LogConnection $LogConnection
        }
    }
    process{
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        if($Script:LogConnection.isEncrypted){
            throw "Use Unprotect-Log first, to edit this logfile!"
            return
        }
        $Lines = $Script:LogConnection.LogLines

        if(![string]::IsNullOrEmpty($PSBoundParameters.Filter)){
            $Lines = $Lines |Where-Object -FilterScript {
                $_LogLine = $_
                $_LogLine.Domain -like $Filter -or
                    $_LogLine.User -like $Filter -or
                    $_LogLine.Message -like $Filter
            }
        }

        if($PSBoundParameters.IncludeDebug -or 
            $PSBoundParameters.IncludeVerbose -or 
            $PSBoundParameters.IncludeInfo -or 
            $PSBoundParameters.IncludeWarning -or 
            $PSBoundParameters.IncludeSuccess -or 
            $PSBoundParameters.IncludeError
        ){
            $selectedSeverityLevels = @()
            if($PSBoundParameters.IncludeDebug){ $selectedSeverityLevels += "DEBUG" }
            if($PSBoundParameters.IncludeVerbose){ $selectedSeverityLevels += "VERBOSE" }
            if($PSBoundParameters.IncludeInfo){ $selectedSeverityLevels += "INFO" }
            if($PSBoundParameters.IncludeWarning){ $selectedSeverityLevels += "WARNING" }
            if($PSBoundParameters.IncludeSuccess){ $selectedSeverityLevels += "SUCCESS" }
            if($PSBoundParameters.IncludeError){ $selectedSeverityLevels += "ERROR" }

            $Lines = $Lines |Where-Object -FilterScript {
                $_LogLine = $_
                $_LogLine.Severity.Name -in $selectedSeverityLevels
            }
        }

        if(![string]::IsNullOrEmpty($PSBoundParameters.First)){ $Lines = $Lines |Select-Object -First $First }
        elseif(![string]::IsNullOrEmpty($PSBoundParameters.Last)){ $Lines = $Lines |Select-Object -Last $Last }

        return $Lines
    }
    end{}
}