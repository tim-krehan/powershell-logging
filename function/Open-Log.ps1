function Open-Log(){
    [CmdletBinding(DefaultParameterSetName="__DEFAULT")]
    [Alias("Connect-Log")]
    param(
        [parameter(Mandatory=$true,Position=0,ParameterSetName="__DEFAULT")]
        [string]
        $Name,
    
        [Parameter(Mandatory=$false,Position=1,ParameterSetName="__DEFAULT")]
        [String]
        $LogPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop),
    
        
        [parameter(Mandatory=$false,Position=2,ParameterSetName="__DEFAULT")]
        [SecureString]
        $Password,
    
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="LOGFULLNAME")]
        [System.IO.FileInfo]
        $LogFullName,
    
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
        if($PsCmdlet.ParameterSetName -eq "LOGFULLNAME"){
            $Script:LogConnection = [LogFile]::new($LogFullName, $LogLevel)
        }
        else{
            $invalidCharIndex = $Name.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars())
            if($invalidCharIndex -gt -1){
                try{
                    if($null -eq $Password){
                        $Script:LogConnection = [LogFile]::new($Name, $LogLevel)
                    }
                    else{
                        $Script:LogConnection = [LogFile]::new($Name, $LogLevel, $Password)
                    }
                }
                catch{
                    throw "There is an invalid character `"$($Name[$invalidCharIndex])`" at position $invalidCharIndex of the logname `"$Name`""
                }
            }
            else{
                if($null -eq $Password){
                    $Script:LogConnection = [LogFile]::new($Name, $LogPath, $LogLevel)
                }
                else{
                    $Script:LogConnection = [LogFile]::new($Name, $LogPath, $LogLevel, $Password)
                }
            }
        }
        $Script:LogConnection.WriteThrough = $WriteThrough
        return $Script:LogConnection
    }
    end{}
}