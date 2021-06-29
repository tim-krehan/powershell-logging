function Open-Log(){
    [CmdletBinding()]
    [Alias("Connect-Log")]
    param(
        [parameter(Mandatory=$true,Position=0)]
        [string]
        $Name,
    
        [Parameter(ParameterSetName="file")]
        [Alias("FullName")]
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
        if([string]::isnullorempty($PSBoundParameters.ShowInfo)){ $ShowInfo = $true }
        if([string]::isnullorempty($PSBoundParameters.ShowWarning)){ $ShowWarning = $true }
        if([string]::isnullorempty($PSBoundParameters.ShowSuccess)){ $ShowSuccess = $true }
        if([string]::isnullorempty($PSBoundParameters.ShowError)){ $ShowError = $true }
    }
    process{
        # try{Close-Log}catch{}
        $LogLevel = @()
        if($ShowDebug){$LogLevel += "DEBUG"}
        if($ShowVerbose){$LogLevel += "VERBOSE"}
        if($ShowInfo){$LogLevel += "INFO"}
        if($ShowWarning){$LogLevel += "WARNING"}
        if($ShowSuccess){$LogLevel += "SUCCESS"}
        if($ShowError){$LogLevel += "ERROR"}
        $Script:LogConnection = [LogFile]::new($Name)

        $Script:LogConnection.AddTarget([LogTargetType]::Console, [ordered]@{
            severitiesToDisplay = [Severity[]]$LogLevel
        })

        if($PsCmdlet.ParameterSetName -eq "file"){
            if(-not($Name -like "*.log")){$Name += ".log"}
            $Script:LogConnection.AddTarget([LogTargetType]::File, [ordered]@{
                filePath = (Join-Path -Path $LogPath -ChildPath $Name)
            })
        }

        return $Script:LogConnection
    }
    end{}
}
