Class Severity {
    $Name
    $Color
    Severity($name) {
        switch ($name) {
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
    [string] ToString() {
        return $this.Name
    }
}
Class LogLine {
    [DateTime]$DateTime
    [string]$User
    [string]$Domain
    [Severity]$Severity
    [String]$Message
    [bool]$Saved = $false

    LogLine($severity, $message) {
        $this.DateTime = Get-Date
        if (-not[string]::IsNullOrEmpty($env:USERNAME)) { $this.User = $env:USERNAME.ToLower() }
        elseif (-not[string]::IsNullOrEmpty($env:USER)) { $this.User = $env:USER.ToLower() }
        if (-not[string]::IsNullOrEmpty($env:USERDNSDOMAIN)) { $this.Domain = $env:USERDNSDOMAIN.ToLower() }
        elseif (-not[string]::IsNullOrEmpty($env:COMPUTERNAME)) { $this.Domain = $env:COMPUTERNAME.ToLower() }
        elseif (-not[string]::IsNullOrEmpty($env:NAME)) { $this.Domain = $env:NAME.ToLower() }
        else { $this.Domain = $(hostname).ToLower() }
        $this.Severity = [Severity]::new($severity)
        $this.Message = $message.trim()
    }
    LogLine([string]$line) {
        $lineRegex = [regex]::new("(\d{4}\-\d{2}\-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{4})\s\-\s(.+?)@(.+?)\s\-\s+([A-Z]{1,7})\s\-\s(.+)$")
        $match = $lineRegex.Match($line)
        if ($match.Success) {
            $this.DateTime = Get-Date $match.Groups[1].Value
            $this.User = $match.Groups[2].Value
            $this.Domain = $match.Groups[3].Value
            $this.Severity = [Severity]::new($match.Groups[4].Value)
            $this.Message = $match.Groups[5].Value.trim()
        }
        else {
            Write-Warning "Skipping Line (Format not recognized)$([Environment]::NewLine)`t`"$line`""
        }
    }
    [string] ToString() {
        return "{0} - {1}@{2} - {3} - {4}" -f @(
            (Get-Date $this.DateTime -Format "yyyy-MM-dd HH:mm:ss.ffff")
            $this.User
            $this.Domain
            $this.Severity.Name.padLeft(7, " ")
            $this.Message
        )
    }
}
Class LogFile {
    [string]$Name
    [string]$FullName
    [string]$Folder
    [string[]]$LogLevels
    [array]$LogLines
    [bool]$WriteThrough = $true
    [bool]$isEncrypted = $false
    [bool]$active

    LogFile($name, $folder, $loglevel) {
        if (Test-Path -Path $folder) {
            $this.LogLevels = $loglevel
            $this.Folder = (Get-Item $folder).FullName
            $this.Name = $name
            $this.FullName = Join-Path -Path $this.Folder -ChildPath "$name.log"
            $this.active = $true
            if (Test-Path -Path $this.FullName) {
                $this.Import()
            }
            else {
                New-Item -Path $this.FullName -ItemType File
            }
        }
        else {
            throw "folder '$folder' not existant"
        }
    }
    LogFile($name, $folder, $loglevel, [SecureString]$password) {
        if (Test-Path -Path $folder) {
            $this.LogLevels = $loglevel
            $this.Folder = (Get-Item $folder).FullName
            $this.Name = $name
            $this.FullName = Join-Path -Path $this.Folder -ChildPath "$name.log"
            $this.active = $true
            if (Test-Path -Path $this.FullName) {
                $this.isEncrypted = $true
                $this.Decrypt($password)
                $this.Import()
            }
            else {
                New-Item -Path $this.FullName -ItemType File
            }
        }
        else {
            throw "folder '$folder' not existant"
        }
    }
    LogFile($path, $loglevel) {
        $this.Folder = Split-Path -Path $path -Parent
        if (Test-Path -Path $this.Folder) {
            $this.LogLevels = $loglevel
            $this.Name = Split-Path -Path $path -Leaf
            $this.FullName = $path
            $this.active = $true
            if (Test-Path -Path $this.FullName -PathType Leaf) {
                $this.Import()
            }
            else {
                New-Item -Path $this.FullName -ItemType File
            }
        }
        else {
            throw "folder '$($this.Folder)' not existant"
        }
    }
    LogFile($path, $loglevel, [SecureString]$password) {
        $this.Folder = Split-Path -Path $path -Parent
        if (Test-Path -Path $this.Folder) {
            $this.LogLevels = $loglevel
            $this.Name = Split-Path -Path $path -Leaf
            $this.FullName = $path
            $this.active = $true
            if (Test-Path -Path $this.FullName -PathType Leaf) {
                $this.isEncrypted = $true
                $this.Decrypt($password)
                $this.Import()
            }
            else {
                New-Item -Path $this.FullName -ItemType File
            }
        }
        else {
            throw "folder '$($this.Folder)' not existant"
        }
    }
    AddLine($severity, $message) {
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        $logline = [LogLine]::new($severity, $message)
        if ($this.LogLevels -contains $logline.Severity.Name) {
            Write-Host -Object $logline.ToString() -ForegroundColor $logline.Severity.Color
        }
        $this.LogLines += $logline
        if ($this.WriteThrough) {
            $this.SaveFile()
        }
    }
    Clear() {
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        $this.LogLines = @()
        New-Item -Path $this.FullName -ItemType File -Force
    }
    Move($newLocation) {
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        if (Test-Path -Path $newLocation) {
            $newLocationItem = Get-Item -Path $newLocation
            if ($newLocationItem -is [System.IO.DirectoryInfo]) {
                $dest = Move-Item -Path $this.FullName -Destination $newLocation -PassThru
                $this.Folder = $dest.DirectoryName
                $this.FullName = $dest.FullName
            }
            else {
                throw "destination needs to be a folder"
            }
        }
        else {
            throw "folder '$newLocation' not existant"
        }
    }
    Rename($newName) {
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        $newPath = Join-Path -Path $this.Folder -ChildPath $newName
        if (-not(Test-Path -Path $newPath)) {
            $dest = Rename-Item -Path $this.FullName -NewName "$newName.log" -PassThru
            $this.Name = $dest.Name
            $this.FullName = $dest.FullName
        }
        else {
            throw "file '$newName' allready existant"
        }
    }
    SaveFile() {
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        $unsavedLines = $this.LogLines | Where-Object -Property "Saved" -EQ $false
        if ($unsavedLines.Count -lt 1) { throw "nothing to save!" }
        $newContent = $unsavedLines | ForEach-Object -Process { $_.ToString() }
        $joinedContent = $newContent -join [Environment]::NewLine
        try {
            Out-File -InputObject $joinedContent -Append -FilePath $this.FullName -Encoding utf8
            $unsavedLines | ForEach-Object -Process { $_.saved = $true }
        }
        catch {
            throw "Error Saving File"
        }
    }
    Import() {
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        $availableContent = (Get-Content $this.FullName) -split [Environment]::NewLine
        foreach ($line in $availableContent) {
            $newline = [LogLine]::new($line)
            $newline.Saved = $true
            $this.LogLines += $newline
        }
    }
    Encrypt([SecureString]$password) {
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        if (-not$this.isEncrypted) {
            $hashKey = $this.HashPassword($password)
            $firstKey = [int32[]]$hashKey.ToCharArray()[0..31]
            $secondKey = [int32[]]$hashKey.ToCharArray()[32..63]
            
            $encryptedLog = Get-Content -Path $this.FullName |
                ConvertTo-SecureString -AsPlainText -Force |
                ConvertFrom-SecureString -Key $firstKey |
                Out-String |
                ConvertTo-SecureString -AsPlainText -Force |
                ConvertFrom-SecureString -Key $secondKey
            Set-Content -Path $this.FullName -Force -Value $encryptedLog
            $this.isEncrypted = $true
        }
        else {
            throw "File allready encrypted"
        }
    }
    Decrypt([SecureString]$password) {
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        if ($this.isEncrypted) {
            $hashKey = $this.HashPassword($password)
            $firstKey = [int32[]]$hashKey.ToCharArray()[0..31]
            $secondKey = [int32[]]$hashKey.ToCharArray()[32..63]
            try{
                $SecureString = Get-Content -Path $this.FullName |
                    ConvertTo-SecureString -Key $secondKey -ErrorAction Stop
            }
            catch{
                throw [exception]::new("Password is incorrect")
            }
            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            $splitSecureString = ([string]([Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr))).split("`n")

            $decryptedSecureString = $splitSecureString[0..($splitSecureString.Length-2)] |ConvertTo-SecureString -Key $firstKey
            $decryptedLog = $decryptedSecureString |ForEach-Object {
              $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($_)
              return [string]([Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr))
            }

            Set-Content -Path $this.FullName -Force -Value $decryptedLog
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            $this.isEncrypted = $false
        }
        else {
            throw "File not encrypted"
        }
    }
    Close(){
        if(!$this.active){throw "Log '$($this.Name)' is inactive! Open it again to use it."}
        $this.active = $false
    }
    hidden [string] HashPassword([SecureString]$password){
        $stringAsStream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write(([PSCredential]::new("user", $password)).GetNetworkCredential().Password)
        $writer.Flush()
        $stringAsStream.Position = 0
        $hashKey = Get-FileHash -InputStream $stringAsStream | Select-Object -ExpandProperty Hash
        return $hashKey
    }
}
function Clear-Log(){
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [parameter()]
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
        if($LogConnection.isEncrypted){
            throw "Use Unprotect-Log first, to edit this logfile!"
            return
        }
        $LogConnection.Clear()
    }
    end{}
}
function Close-Log(){
    [CmdletBinding()]
    param(
        [parameter()]
        [LogFile]
        $LogConnection = $Script:LogConnection
    )
    begin{
    }
    process{
        if($null -eq $Script:LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        $LogConnection.close()
        Remove-Variable "LogConnection" -Scope "Script"
    }
    end{}
}
function Get-Log(){
    [CmdletBinding()]
    param(
        [parameter()]
        [LogFile]
        $LogConnection = $Script:LogConnection
    )
    begin{
    }
    process{
        if($null -eq $LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        return $LogConnection
    }
    end{}
}
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
    }
    process{
        if($null -eq $LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        if($LogConnection.isEncrypted){
            throw "Use Unprotect-Log first, to edit this logfile!"
            return
        }
        $Lines = $LogConnection.LogLines

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
function Move-Log(){
  [CMDLetBinding(PositionalBinding=$false)]
  param(
      # new directory
      [Parameter(Mandatory=$true, Position=0)]
      [string]
      $Path,

      [parameter()]
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
      $LogConnection.Move($Path)
  }
  end{}
}
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
        # try{Close-Log}catch{}
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
function Protect-Log(){
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [SecureString]$Password,

    [parameter()]
    [LogFile]
    $LogConnection = $Script:LogConnection
  )
  begin{
  }
  process{
      if($null -eq $LogConnection){
          throw "Use `"Open-Log`" first, to connect to a logfile!"
          return
      }
      $LogConnection.encrypt($Password)
  }
  end{}
}
function Rename-Log(){
  [CMDLetBinding(PositionalBinding=$false)]
  param(
      # new directory
      [Parameter(Mandatory=$true, Position=0)]
      [string]
      $NewName,

      [parameter()]
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
      $LogConnection.Rename($NewName)
  }
  end{}
}
function Save-Log(){
    [CmdletBinding()]
    param(
        [parameter()]
        [LogFile]
        $LogConnection = $Script:LogConnection
    )
    begin{
    }
    process{
        if($null -eq $LogConnection){
            throw "Use `"Open-Log`" first, to connect to a logfile!"
            return
        }
        if($LogConnection.isEncrypted){
            throw "Use Unprotect-Log first, to edit this logfile!"
            return
        }
        $LogConnection.SaveFile()
    }
    end{}
}
function Switch-Log(){
  param(
    [parameter(Mandatory=$true)]
    [LogFile]$LogConnection
  )
  begin{}
  process{
    $Script:LogConnection = $LogConnection
  }
  end{}
}
function Unprotect-Log(){
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [SecureString]$Password,

    [parameter()]
    [LogFile]
    $LogConnection = $Script:LogConnection
  )
  begin{
  }
  process{
      if($null -eq $LogConnection){
          throw "Use `"Open-Log`" first, to connect to a logfile!"
          return
      }
      $LogConnection.decrypt($Password)
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
        $LogLine,
        
        [parameter()]
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
        if($LogConnection.isEncrypted){
            throw "Use Unprotect-Log first, to edit this logfile!"
            return
        }
        $LogConnection.AddLine($Severity, $LogLine)
    }
    end{}
}
