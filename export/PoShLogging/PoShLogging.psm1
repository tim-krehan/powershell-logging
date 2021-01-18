Class Severity{
    $Name
    $Color
    Severity($name){
        switch($name){
            "DEBUG" {
                $this.Color = [System.ConsoleColor]::DarkBlue
                $this.Name = "DEBUG"
                break
            }
            "VERBOSE" {
                $this.Color = [System.ConsoleColor]::DarkYellow
                $this.Name = "VERBOSE"
                break
            }
            "INFO" {
                $this.Color = [System.ConsoleColor]::White
                $this.Name = "INFO"
                break
            }
            "WARNING" {
                $this.Color = [System.ConsoleColor]::Yellow
                $this.Name = "WARNING"
                break
            }
            "SUCCESS" {
                $this.Color = [System.ConsoleColor]::Green
                $this.Name = "SUCCESS"
                break
            }
            "ERROR" {
                $this.Color = [System.ConsoleColor]::Red
                $this.Name = "ERROR"
                break
            }
            default {
                break
            }
        }
    }
    [string] ToString(){
        return $this.Name
    }
}
Class LogLine{
    [DateTime]$DateTime
    [string]$User
    [string]$Domain
    [Severity]$Severity
    [String]$Message
    [bool]$Saved = $false

    LogLine($severity, $message){
        $this.DateTime = Get-Date
        $this.User = $env:USERNAME.ToLower()
        $this.Domain = $env:USERDNSDOMAIN.ToLower()
        $this.Severity = [Severity]::new($severity)
        $this.Message = $message.trim()
    }
    LogLine([string]$line){
        $lineRegex = [regex]::new("(\d{4}\-\d{2}\-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{4})\s\-\s(.+?)@(.+?)\s\-\s+([A-Z]{1,7})\s\-\s(.+)$")
        $match = $lineRegex.Match($line)
        if($match.Success){
            $this.DateTime = Get-Date $match.Groups[1].Value
            $this.User = $match.Groups[2].Value
            $this.Domain = $match.Groups[3].Value
            $this.Severity = [Severity]::new($match.Groups[4].Value)
            $this.Message = $match.Groups[5].Value.trim()
        }
        else{
            Write-Warning "Skipping Line (Format not recognized)$([Environment]::NewLine)`t`"$line`""
        }
    }
    [string] ToString(){
        return "{0} - {1}@{2} - {3} - {4}" -f @(
            (Get-Date $this.DateTime -Format "yyyy-MM-dd HH:mm:ss.ffff")
            $this.User
            $this.Domain
            $this.Severity.Name.padLeft(7, " ")
            $this.Message
        )
    }
}
Class LogFile{
    [string]$Name
    [string]$FullName
    [string]$Folder
    [string[]]$LogLevels
    [array]$LogLines
    [bool]$WriteThrough = $true

    LogFile($name, $folder, $loglevel){
        if(Test-Path -Path $folder){
            $this.LogLevels = $loglevel
            $this.Folder = (Get-Item $folder).FullName
            $this.Name = $name
            $this.FullName = "{0}\{1}.log" -f $this.Folder, $name
            if(Test-Path -Path $this.FullName){
                $this.Import()
            }
            else{
                New-Item -Path $this.FullName -ItemType File
            }
        }
        else{
            throw "folder '$folder' not existant"
        }
    }
    AddLine($severity, $message){
        $logline = [LogLine]::new($severity, $message)
        if($this.LogLevels -contains $logline.Severity.Name){
            Write-Host -Object $logline.ToString() -ForegroundColor $logline.Severity.Color
        }
        $this.LogLines += $logline
        if($this.WriteThrough){
            $this.SaveFile()
        }
    }
    Clear(){
        $this.LogLines = @()
        New-Item -Path $this.FullName -ItemType File -Force
    }
    SaveFile(){
        $unsavedLines = $this.LogLines |Where-Object -Property "Saved" -EQ $false
        if($unsavedLines.Count -lt 1){throw "nothing to save!"}
        $newContent = $unsavedLines |ForEach-Object -Process {$_.ToString()}
        $joinedContent = $newContent -join [Environment]::NewLine
        try{
            Out-File -InputObject $joinedContent -Append -FilePath $this.FullName -Encoding utf8
            $unsavedLines |ForEach-Object -Process {$_.saved = $true}
        }
        catch{
            throw "Error Saving File"
        }
    }
    Import(){
        $availableContent = (Get-Content $this.FullName) -split [Environment]::NewLine
        foreach($line in $availableContent){
            $newline = [LogLine]::new($line)
            $newline.Saved = $true
            $this.LogLines += $newline
        }
    }
}
function Clear-Log(){
    [CmdletBinding()]
    param()
    begin{
    }
    process {
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        $Script:LogConnection.Clear()
    }
    end{}
}
function Close-Log(){
    [CmdletBinding()]
    param()
    begin{
    }
    process{
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        Remove-Variable "LogConnection" -Scope "Script"
    }
    end{}
}
function Get-Log(){
    [CmdletBinding()]
    param()
    begin{
    }
    process{
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        return $Script:LogConnection
    }
    end{}
}
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
function Save-Log(){
    [CmdletBinding()]
    param()
    begin{
    }
    process{
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        $Script:LogConnection.SaveFile()
    }
    end{}
}
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
    }
    process {
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        $Script:LogConnection.AddLine($Severity, $LogLine)
    }
    end{}
}
