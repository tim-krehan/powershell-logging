function Open-Log(){
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,Position=0)]
        [string]
        $Name,
    
        [Parameter(Mandatory=$false,Position=1)]
        [String]
        $LogPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop),
    
        [switch]
        $ShowDebug,

        [switch]
        $ShowVerbose,

        [switch]
        $ShowInfo,
        
        [switch]
        $ShowWarning,
        
        [switch]
        $ShowSuccess,
        
        [switch]
        $ShowError
    )
    begin{
    }
    process{
        try{Close-Log}catch{}
        $LogLevel = @("INFO", "WARNING", "SUCCESS", "ERROR")
        if($ShowDebug -or $ShowVerbose -or $ShowInfo -or $ShowWarning -or $ShowSuccess -or $ShowError){
            $LogLevel = @()
            if($ShowDebug){$LogLevel += "DEBUG"}
            if($ShowVerbose){$LogLevel += "VERBOSE"}
            if($ShowInfo){$LogLevel += "INFO"}
            if($ShowWarning){$LogLevel += "WARNING"}
            if($ShowSuccess){$LogLevel += "SUCCESS"}
            if($ShowError){$LogLevel += "ERROR"}
        }
        $Script:LogConnection = [LogFile]::new($Name, $LogPath, $LogLevel)
        return $Script:LogConnection
    }
    end{}
}