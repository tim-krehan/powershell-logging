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
            $this.LogLines += [LogLine]::new($line)
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
            throw "Use `"New-Log`" first, to connect to a logfile!"
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
            throw "Use `"New-Log`" first, to connect to a logfile!"
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
            throw "Use `"New-Log`" first, to connect to a logfile!"
            return
        }
        return $Script:LogConnection
    }
    end{}
}
function Open-Log(){
    [CmdletBinding()]
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
        $ShowError
    )
    begin{
    }
    process{
        try{Close-Log}catch{}
        $LogLevel = @("INFO", "WARNING", "SUCCESS", "ERROR")
        if($ShowDebug -or $ShowVerbose -or $ShowInfo -or $ShowWarning -or $ShowSuccess -or $ShowError){
            $LogLevel = @()
            if($ShowDebug){$LogLevel += "DEBUG"}
            if($ShowVerbose){$LogLevel += "VERBOSE"}
            if($ShowInfo){$LogLevel += "INFO"}
            if($ShowWarning){$LogLevel += "WARNING"}
            if($ShowSuccess){$LogLevel += "SUCCESS"}
            if($ShowError){$LogLevel += "ERROR"}
        }
        $Script:LogConnection = [LogFile]::new($Name, $LogPath, $LogLevel)
        return $Script:LogConnection
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
            throw "Use `"New-Log`" first, to connect to a logfile!"
            return
        }
        $Script:LogConnection.AddLine($Severity, $LogLine)
    }
    end{}
}

# SIG # Begin signature block
# MIITmAYJKoZIhvcNAQcCoIITiTCCE4UCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUD8iP6ZkT2I/lFc41RKkTD7e/
# 0TugghEFMIIFoTCCBImgAwIBAgITIQAAAA9IvEBUBCwiDgAAAAAADzANBgkqhkiG
# 9w0BAQsFADBJMRIwEAYKCZImiZPyLGQBGRYCZGUxGTAXBgoJkiaJk/IsZAEZFgli
# YXVncnVwcGUxGDAWBgNVBAMTD0JhdWdydXBwZVJvb3RDQTAeFw0yMDAyMjkxMDA3
# MDRaFw00MDAyMjQxMDA3MDRaMFExEjAQBgoJkiaJk/IsZAEZFgJkZTEZMBcGCgmS
# JomT8ixkARkWCWJhdWdydXBwZTEgMB4GA1UEAxMXQmF1Z3J1cHBlSW50ZXJtZWRp
# YXRlQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqHlEJc/PWaisl
# bixjH/0FVlNrt4EQjKZIndyH03T+lk4tXnBFO8IXrYl2QZIMydc7T/6mSurxmJgo
# jN0rq9wudYmm6n+JGocCakbZop0pObG6fR6lPkRekRhgM49H4Bmr+kgE8cwb2PrI
# ozsfbPiLb2yk9D9YPsPc47NapNYW5P85oWU0IP8A35IsdeMaZcdey/N4wvSFqp2E
# gXnP6rJiBBi80KkAl1sHU/3vjCDlqlvw9dL01jaaoA4/FjUBdqT2quzCqg8fJaT9
# m1iIQEywG88B4GFk+Kav8UZ4lWAIrXsoV4ULxATa7iaOQkVsa0pnVCV7fiMDeP+2
# 6W54nIzjAgMBAAGjggJ4MIICdDASBgkrBgEEAYI3FQEEBQIDBwAHMCMGCSsGAQQB
# gjcVAgQWBBQX+cFMSgE+aG9lJtUTAF2vo0ht4TAdBgNVHQ4EFgQUn4IO8r6ZXtkX
# swxcXCLGDah4Qm8wPgYJKwYBBAGCNxUHBDEwLwYnKwYBBAGCNxUIhs+tHYabxBGH
# 1ZUBhLfjOYfF71WBSISE2QOCvP1zAgFmAgEBMAsGA1UdDwQEAwIBhjAPBgNVHRMB
# Af8EBTADAQH/MB8GA1UdIwQYMBaAFGTzXjOshurZ8ISq/JxFtuRpDZNSMIHVBgNV
# HR8Egc0wgcowgceggcSggcGGgb5sZGFwOi8vL0NOPUJhdWdydXBwZVJvb3RDQSxD
# Tj1icnotbnVlLWNlcnQwNCxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2Vydmlj
# ZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1iYXVncnVwcGUsREM9
# ZGU/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNS
# TERpc3RyaWJ1dGlvblBvaW50MIHCBggrBgEFBQcBAQSBtTCBsjCBrwYIKwYBBQUH
# MAKGgaJsZGFwOi8vL0NOPUJhdWdydXBwZVJvb3RDQSxDTj1BSUEsQ049UHVibGlj
# JTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixE
# Qz1iYXVncnVwcGUsREM9ZGU/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNz
# PWNlcnRpZmljYXRpb25BdXRob3JpdHkwDQYJKoZIhvcNAQELBQADggEBAH1t4wIU
# 1V9C0NHa+M7OEoSApxkWEWb/d7ZnTV7WbLM3RbKYz4HW9NnXR2vXN9NcUOyCdzMW
# zcxJ9yfP6qi2QDv+ObQ74UrF0WfKQmDOQXjdJQF69P8lsCyVhfq5Yw7t9JO/QRrB
# roczHOk062gveWWoA7DeamXQN3myHGZ6qDMebUMtCYhRJFRh5SlW0QIusgswwJKe
# Cpmmnhu2QuAstaqkqwGmSUpoRCHaniLTqTRR1bXAJFuW4aS1zobvHl5aOEjNCTNN
# 6Zg4SOVV8WcRC5rCIfBREnzHkjP1/6q6GkqxhAWdQCYwuxQgOdGODWkhuXh2XO6o
# Kn/KPUK3lhTFG8owggWpMIIEkaADAgECAhMZAAAaolPA5AINVjz2AAIAABqiMA0G
# CSqGSIb3DQEBCwUAMEUxEjAQBgoJkiaJk/IsZAEZFgJkZTEZMBcGCgmSJomT8ixk
# ARkWCWJhdWdydXBwZTEUMBIGA1UEAxMLQmF1Z3J1cHBlQ0EwHhcNMjAwNTE0MTMw
# MTIxWhcNMjIwNTE0MTMwMTIxWjCB0DESMBAGCgmSJomT8ixkARkWAmRlMRkwFwYK
# CZImiZPyLGQBGRYJYmF1Z3J1cHBlMRkwFwYDVQQLExBGYUJSWkRldXRzY2hsYW5k
# MRkwFwYDVQQLDBBfQlJaIERldXRzY2hsYW5kMRMwEQYDVQQLEwpEYXRhY2VudGVy
# MSMwIQYDVQQLExpJVCBJbmZyYXN0cnVjdHVyZSBTZXJ2aWNlczEaMBgGA1UECxMR
# U3lzdGVtIE9wZXJhdGlvbnMxEzARBgNVBAMTClRpbSBLcmVoYW4wggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDMSjgOMu4Fmj25jJkMEMPxxE/bA5O1jGjS
# 5yETLCrMNLheJmC8pzgZOUvcyg2e3oKekLkIPn7iHoUNDkGdnSL/xeJn1w7Q8cBY
# QiyUyvDEIPhsr29/qWLrIUDPGdEmZwD6x+vSZwXRd+1SQVUGKGBDSe3Z/iNrloRR
# IzjMhuB8yL4rFKX5VUOa7AQk2gLrAZbGLro9jgff+yZqqPwDbj8K5WvAkrdjPsdN
# PDq6hLENHjFrgqD6Vfc3PksUeVlSYWJul2NkIVQ2+VZxST6PSPiB1u7oC8IP9jHh
# sEBwj25Bt+2T61tH5uh7DIkTKMfoSnya8dA2H1QZpW17NRwrLJD9AgMBAAGjggIE
# MIICADA9BgkrBgEEAYI3FQcEMDAuBiYrBgEEAYI3FQiGz60dhpvEEYfVlQGEt+M5
# h8XvVYFIg/r4Stj0GwIBZgIBAjATBgNVHSUEDDAKBggrBgEFBQcDAzALBgNVHQ8E
# BAMCB4AwGwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUaMqL
# rjoGAkEPGT+P+NWtjpZVcNYwHwYDVR0jBBgwFoAUHA4LiTeELbAdnzKOWhtWGlsp
# p3YwUQYDVR0fBEowSDBGoESgQoZAaHR0cDovL2Jyei1udWUtY2VydDA2LmJhdWdy
# dXBwZS5kZS9DZXJ0RW5yb2xsL0JhdWdydXBwZUNBKDIpLmNybDCBvgYIKwYBBQUH
# AQEEgbEwga4wgasGCCsGAQUFBzAChoGebGRhcDovLy9DTj1CYXVncnVwcGVDQSxD
# Tj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049
# Q29uZmlndXJhdGlvbixEQz1iYXVncnVwcGUsREM9ZGU/Y0FDZXJ0aWZpY2F0ZT9i
# YXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwLAYDVR0RBCUw
# I6AhBgorBgEEAYI3FAIDoBMMEVRpbS5LcmVoYW5AYnJ6LmV1MA0GCSqGSIb3DQEB
# CwUAA4IBAQAggBGnNXS7nvUjnaFyOLwwdmrFyxwzW6iFApLyTMnax/N+QDBvF0ER
# +N1M7t5N1scqOdlCrKawwKmcor4bNBvZPApLM+cbgbX1vCW3zcUU6dUh0vcviwQP
# N1SqofnewlKXjZMgyec/3SBP3MkYbtyNgXY8+8k9A8X5VDh+HnG+8fGZvR6ZNmTl
# QOlUOzAXq09y26q8mvi9K/HB3NU68ubowilTjZwEpTC+VXP9eLPnfie9Mp7In8FN
# MxzwDFeKYFKDgmbTsojNTL1WGvP4/NeQMn34D5WnW4uls0NJp1Y3UwlX2EEvEkam
# xdF6SpZ4GxOaPerUQppwIb4m8J2eeYS1MIIFrzCCBJegAwIBAgITKwAAABTKLckZ
# frqWAAAHAAAAFDANBgkqhkiG9w0BAQsFADBRMRIwEAYKCZImiZPyLGQBGRYCZGUx
# GTAXBgoJkiaJk/IsZAEZFgliYXVncnVwcGUxIDAeBgNVBAMTF0JhdWdydXBwZUlu
# dGVybWVkaWF0ZUNBMB4XDTIwMDIyOTEwMTIyOVoXDTI1MDIyNzEwMTIyOVowRTES
# MBAGCgmSJomT8ixkARkWAmRlMRkwFwYKCZImiZPyLGQBGRYJYmF1Z3J1cHBlMRQw
# EgYDVQQDEwtCYXVncnVwcGVDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAKjdHV7kJWIwGMZ+eaeEMlLVVr7XG+HQ92SAuRJuXTW+c9uJpvS+OPqrnbk0
# mF8vVVhGxaqEiCSOA84IGlik/4e+L7xn66t0SCv5BEnk1QGcuNIDWacnv7RpVgHz
# Itsrsj06Zk+Ize4Fnq54j3wkXYPYmsRozdbgKkKi0foj+sLxK9IXQQUccx8pETN6
# w0uFS2v3oP2DSjfLoUFziUHgyAky90oKOgvbUc6srHh6YuZbIqtXbqMNVrTkqHH0
# lnJLQKEDkVpXXqfO9fjD39P+oXtxm4JFI8fb094g/a6p4tJxlTVZK/kVZoq8kSU8
# 2cLemoerq2xjLJWhXxvaSAiLdyECAwEAAaOCAoowggKGMBIGCSsGAQQBgjcVAQQF
# AgMCAAIwIwYJKwYBBAGCNxUCBBYEFIpK6jrHXBgFTI0EneolpQIF1wagMB0GA1Ud
# DgQWBBQcDguJN4QtsB2fMo5aG1YaWymndjA9BgkrBgEEAYI3FQcEMDAuBiYrBgEE
# AYI3FQiGz60dhpvEEYfVlQGEt+M5h8XvVYFIhrP2QP6kawIBZAIBBjALBgNVHQ8E
# BAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBSfgg7yvple2RezDFxc
# IsYNqHhCbzCB4AYDVR0fBIHYMIHVMIHSoIHPoIHMhoHJbGRhcDovLy9DTj1CYXVn
# cnVwcGVJbnRlcm1lZGlhdGVDQSg3KSxDTj1icnotbnVlLWNlcnQwNSxDTj1DRFAs
# Q049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmln
# dXJhdGlvbixEQz1iYXVncnVwcGUsREM9ZGU/Y2VydGlmaWNhdGVSZXZvY2F0aW9u
# TGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIHKBggr
# BgEFBQcBAQSBvTCBujCBtwYIKwYBBQUHMAKGgapsZGFwOi8vL0NOPUJhdWdydXBw
# ZUludGVybWVkaWF0ZUNBLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNl
# cyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWJhdWdydXBwZSxEQz1k
# ZT9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1
# dGhvcml0eTANBgkqhkiG9w0BAQsFAAOCAQEAauEnnYT9h1KfyxJLqc+5VxuWZV1A
# dfUzeuZK2l/Hiev2wCSsgikoduCG4/81Oxish71lgXaJUC8ltARBHODLTwozJTLE
# mhwytqV275DV7KA8tzWfjAks0V+rNUffAig1DIutfBV0VE3uIJHFtWuoTOMzaj+C
# ZUwezFKR+p/jC3ZeU6ni9cQGE3Ts1WMj93iZEYSRKKKqfIMYYs0f4Hh+GTdqIdrp
# WooVXACrhspOR0wI5LmecEaKOBS62siUMRhSKN/dy8F0wjdSsFKIkT96CLng0xIg
# Q3cekpHVg/hf3yerA9QpKcFcZqnCC3PVAuhzdJIrNWbjNevWRORR7R/AKjGCAf0w
# ggH5AgEBMFwwRTESMBAGCgmSJomT8ixkARkWAmRlMRkwFwYKCZImiZPyLGQBGRYJ
# YmF1Z3J1cHBlMRQwEgYDVQQDEwtCYXVncnVwcGVDQQITGQAAGqJTwOQCDVY89gAC
# AAAaojAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQU6utv+olRQLjX5iO6hsEyZ9oDynEwDQYJKoZI
# hvcNAQEBBQAEggEAgv1OOmMvZqBcn0sULCMEzBQ91te/TtD3O7YwHQSReY+7P6Ru
# 7CIv1L9ktXIdsOdfPFWiTeUxk0MQ5rb4KMp+gHV/KDeim9WIgR3xjoojr1DIG9x7
# Y7kK+dPxZC4bTd+O86YaRJAPsg6fJaxWN/b7ExRxbnJUxLZQOTM3z7iGC8RtVJ0L
# 1j0HimPPUj4aaK6tS4cROBmI+dmni3KIxzgl2fYQecp5RsLSnI2QaSjVqQyzDhhy
# pERVSOgcel0KpXIq4aiurxR+y82SoNp7P3snmSse8f2JxZAiDiaMyVZHR85Nf6/1
# rsR4ioO0A0XAICqaU+DW9POpiNlDZZNYtqpdHw==
# SIG # End signature block
