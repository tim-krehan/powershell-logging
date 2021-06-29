function Add-LogTarget() {
  [CMDLetBinding(PositionalBinding = $false, DefaultParameterSetName = "file")]
  param(
    [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "file", ValueFromPipelineByPropertyName = $true)]
    [string]
    $FullName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Host", "Stream", "None")]
    [string]
    $ConsoleType = "Host",

    [Parameter(Mandatory = $true, ParameterSetName = "console")]
    [Switch]
    $Console,
    
    [Parameter(Mandatory = $false, ParameterSetName = "console")]
    [switch]
    $ShowDebug,

    [Parameter(Mandatory = $false, ParameterSetName = "console")]
    [switch]
    $ShowVerbose,

    [Parameter(Mandatory = $false, ParameterSetName = "console")]
    [switch]
    $ShowInfo,
    
    [Parameter(Mandatory = $false, ParameterSetName = "console")]
    [switch]
    $ShowWarning,
    
    [Parameter(Mandatory = $false, ParameterSetName = "console")]
    [switch]
    $ShowSuccess,
    
    [Parameter(Mandatory = $false, ParameterSetName = "console")]
    [switch]
    $ShowError,

    [parameter()]
    [LogFile]
    $LogConnection = $Script:LogConnection
  )
  begin {
    if ([string]::isnullorempty($PSBoundParameters.ShowInfo)) { $ShowInfo = $true }
    if ([string]::isnullorempty($PSBoundParameters.ShowWarning)) { $ShowWarning = $true }
    if ([string]::isnullorempty($PSBoundParameters.ShowSuccess)) { $ShowSuccess = $true }
    if ([string]::isnullorempty($PSBoundParameters.ShowError)) { $ShowError = $true }
  }
  process {
    if ($null -eq $LogConnection) {
      throw "Use `"Open-Log`" first, to connect to a logfile!"
      return
    }
    switch ($PsCmdlet.ParameterSetName) {
      "file" {
        $fileTarget = $LogConnection.AddTarget([LogTargetType]::File, [ordered]@{
            filePath = $FullName
          })
        break;
      }
      "console" {
        if ($LogConnection.Targets.Type -Contains "Console") {
          throw "there can only be one console target!"
        }
        $LogLevel = @()
        if ($ShowDebug) { $LogLevel += "DEBUG" }
        if ($ShowVerbose) { $LogLevel += "VERBOSE" }
        if ($ShowInfo) { $LogLevel += "INFO" }
        if ($ShowWarning) { $LogLevel += "WARNING" }
        if ($ShowSuccess) { $LogLevel += "SUCCESS" }
        if ($ShowError) { $LogLevel += "ERROR" }
        switch ($ConsoleType) {
          "Host" {
            $consoleTarget = $LogConnection.AddTarget([LogTargetType]::Console, [ordered]@{
                severitiesToDisplay = [Severity[]]$LogLevel
              })
            break
          }
          "Stream" {
            $consoleTarget = $LogConnection.AddTarget([LogTargetType]::Stream, [ordered]@{
                severitiesToDisplay = [Severity[]]$LogLevel
              })
            break
          }
          default {
            # add no console target
          }
        }
        break;
      }
    }

    return $LogConnection
  }
  end {}
}
