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
    [array]$LogLines
    [bool]$WriteThrough = $true

    LogFile($name, $folder){
        if(Test-Path -Path $folder){
            $this.Folder = $folder
            $this.Name = $name
            $this.FullName = "{0}\{1}.log" -f $folder, $name
            if(Test-Path -Path $this.FullName){
                $this.Import()
            }
            else{
                New-Item -Path $this.FullName -ItemType File
            }
        }
        else{
            Write-Error "folder '$folder' not existant"
        }
    }
    AddLine($severity, $message){
        $logline = [LogLine]::new($severity, $message)
        Write-Host -Object $logline.ToString() -ForegroundColor $logline.Severity.Color
        $this.LogLines += $logline
        if($this.WriteThrough){
            $this.SaveFile()
        }
    }
    Clear(){
        $this.LogLines = @()
        New-Item -Path $this.FullName -ItemType File
    }
    SaveFile(){
        $unsavedLines = $this.LogLines |Where-Object -Property "Saved" -EQ $false
        if($unsavedLines.Count -lt 1){Write-Error "nothing to save!"}
        $newContent = $unsavedLines |ForEach-Object -Process {$_.ToString()}
        $joinedContent = $newContent -join [Environment]::NewLine
        try{
            Out-File -InputObject $joinedContent -Append -FilePath $this.FullName -Encoding utf8
            $unsavedLines |ForEach-Object -Process {$_.saved = $true}
        }
        catch{
            Write-Error "Error Saving File"
        }
    }
    Import(){
        $availableContent = (Get-Content $this.FullName) -split [Environment]::NewLine
        foreach($line in $availableContent){
            $this.LogLines += [LogLine]::new($line)
        }
    }
}