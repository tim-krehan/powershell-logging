function Open-Log(){
    [CmdletBinding()]
    [Alias("Connect-Log")]
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
        $ShowError,

        [switch]
        $WriteThrough
    )
    begin{
        if([string]::isnullorempty($PSBoundParameters.ShowInfo)){ $ShowInfo = $true }
        if([string]::isnullorempty($PSBoundParameters.ShowWarning)){ $ShowWarning = $true }
        if([string]::isnullorempty($PSBoundParameters.ShowSuccess)){ $ShowSuccess = $true }
        if([string]::isnullorempty($PSBoundParameters.ShowError)){ $ShowError = $true }
        if([string]::isnullorempty($PSBoundParameters.WriteThrough)){ $WriteThrough = $true }
    }
    process{
        try{Close-Log}catch{}
        $LogLevel = @()
        if($ShowDebug){$LogLevel += "DEBUG"}
        if($ShowVerbose){$LogLevel += "VERBOSE"}
        if($ShowInfo){$LogLevel += "INFO"}
        if($ShowWarning){$LogLevel += "WARNING"}
        if($ShowSuccess){$LogLevel += "SUCCESS"}
        if($ShowError){$LogLevel += "ERROR"}
        $Script:LogConnection = [LogFile]::new($Name, $LogPath, $LogLevel)
        $Script:LogConnection.WriteThrough = $WriteThrough
        return $Script:LogConnection
    }
    end{}
}