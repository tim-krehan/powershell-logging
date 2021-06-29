function Open-Log(){
    [CmdletBinding()]
    [Alias("Connect-Log")]
    param(
        [parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,
    
        [Parameter(ParameterSetName="file",ValueFromPipelineByPropertyName=$true)]
        [Alias("DirectoryName")]
        [String]
        $LogPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop),

        [Parameter(Mandatory=$false)]
        [ValidateSet("Host", "Stream", "None")]
        [string]
        $ConsoleType = "Host",
    
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

        switch($ConsoleType){
            "Host" {
                $consoleTarget = $Script:LogConnection.AddTarget([LogTargetType]::Console, [ordered]@{
                    severitiesToDisplay = [Severity[]]$LogLevel
                })
                break
            }
            "Stream" {
                $consoleTarget = $Script:LogConnection.AddTarget([LogTargetType]::Stream, [ordered]@{
                    severitiesToDisplay = [Severity[]]$LogLevel
                })
                break
            }
            default {
                # add no console target
            }
        }


        if($PsCmdlet.ParameterSetName -eq "file"){
            if(-not($Name -like "*.log")){$Name += ".log"}
            $fileTarget = $Script:LogConnection.AddTarget([LogTargetType]::File, [ordered]@{
                filePath = (Join-Path -Path $LogPath -ChildPath $Name)
            })
        }

        return $Script:LogConnection
    }
    end{}
}
