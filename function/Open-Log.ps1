function Open-Log(){
    param(
        [parameter(Mandatory=$true,Position=0)]
        [string]
        $Name,
    
        [Parameter(Mandatory=$false,Position=1)]
        [String]
        $LogPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    )
    begin{}
    process{
        $Script:LogConnection = [LogFile]::new($Name, $LogPath)
        return $Script:LogConnection
    }
    end{}
}