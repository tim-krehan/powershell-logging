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

    LogFile($name, $folder, $loglevel) {
        if (Test-Path -Path $folder) {
            $this.LogLevels = $loglevel
            $this.Folder = (Get-Item $folder).FullName
            $this.Name = $name
            $this.FullName = Join-Path -Path $this.Folder -ChildPath "$name.log"
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
        $this.LogLines = @()
        New-Item -Path $this.FullName -ItemType File -Force
    }
    Move($newLocation) {
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
        $availableContent = (Get-Content $this.FullName) -split [Environment]::NewLine
        foreach ($line in $availableContent) {
            $newline = [LogLine]::new($line)
            $newline.Saved = $true
            $this.LogLines += $newline
        }
    }
    Encrypt([SecureString]$password) {
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