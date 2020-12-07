function Get-LogConfig(){
    param()
    begin {
        $configFolder =  "$env:APPDATA\b550.log"
        if(!(Test-Path $configFolder)){New-Item -Path $configFolder -ItemType Directory}
        $configFile = "$configFolder\config.json"
        if(!(Test-Path $configFile)){New-Item -Path $configFile -ItemType File -Value "{}" |Out-Null}
        [pscustomobject]$currentConfig = Get-Content $configFile |ConvertFrom-Json
    }
    process{
        return $currentConfig
    }
    end{

    }
}
function Set-LogConfig(){
    [CMDLetBinding(DefaultParameterSetName="default")]
    param(
        [parameter(parameterSetName="default")]
        [string]
        $Location,

        [parameter(parameterSetName="default")]
        [string]
        $LogName,

        [parameter(ValueFromPipeline=$true,Mandatory=$true,ParameterSetName="pipeline")]
        [PSCustomObject]
        $InputObject
    )
    begin {
        $configFolder =  "$env:APPDATA\b550.log"
        if(!(Test-Path $configFolder)){New-Item -Path $configFolder -ItemType Directory}
        $configFile = "$configFolder\config.json"
        if(!(Test-Path $configFile)){New-Item -Path $configFile -ItemType File -Value "{}"}
        [pscustomobject]$currentConfig = Get-Content $configFile |ConvertFrom-Json
    }
    process{
        if(![string]::IsNullOrEmpty($InputObject)){
            foreach($key in ($InputObject |Get-Member -MemberType NoteProperty |Select-Object -ExpandProperty name)){
                Set-Variable -Name $key -Value $InputObject.$key
            }
        }
        try{
            # set defaultlLocation
            if(![string]::IsNullOrEmpty($Location)){
                if(!(Test-Path $Location)){
                    throw "'$Location' ist nicht vorhanden!"
                }
                $LocationItem = Get-Item $Location
                if($LocationItem.Attributes.toString().Split(",").Trim() -notcontains "Directory"){
                    throw "'$Location' ist kein Ordner!"
                }
                if($null -eq $currentConfig.Location){
                    Add-Member -InputObject $currentConfig -Name "Location" -Value $LocationItem.FullName -MemberType NoteProperty
                }
                else{
                    $currentConfig.Location = $LocationItem.FullName
                }
            }

            # set default name
            if(![string]::IsNullOrEmpty($LogName)){
                if($LogName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -gt 0){
                    throw "'$LogName' enthält ungültige Zeichen!"
                }
                if($null -eq $currentConfig.LogName){
                    Add-Member -InputObject $currentConfig -Name "LogName" -Value $LogName -MemberType NoteProperty
                }
                else{
                    $currentConfig.LogName = $LogName
                }
            }
        }
        catch{
            Write-Error $Error[0].Exception.Message
        }
    }
    end{
        $jsonConfig = $currentConfig |ConvertTo-Json -Depth 100 -Compress:$true
        Out-File -InputObject $jsonConfig -FilePath $configFile -Encoding utf8 -Force
    }
}
function Write-Log(){
    [CMDLetBinding(PositionalBinding=$false)]
    [Alias("ulog")]
    param(
        # severity of logline
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("NOTICE", "INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]
        $severity,

        # actual error text
        [Parameter(Mandatory=$true, Position=1, ValueFromRemainingArguments=$true)]
        [string]
        $logline,

        # logfile location
        [Parameter(Mandatory=$false)]
        [string]
        $logname = "powershell"
    )
    begin{
        $configFile = "$env:APPDATA\b550.log\config.json"
        if(Test-path $configFile){
            $defaultConfig = Get-Content $configFile |ConvertFrom-Json
            if($null -ne $defaultConfig.Location){
                $logfile = $defaultConfig.Location
            }
            else{
                $logfile = "~"
            }
            if($null -ne $defaultConfig.LogName){
                if($null -eq $logname){
                    $logfile += "\" + $defaultConfig.LogName
                }
                else{
                    $logfile += "\$logname"
                }
            }
            else{
                $logfile += "\powershell"
            }
            $logfile += ".log"
        }
        else{
            if([string]::IsNullOrEmpty($logname)){
                $logfile = "~\powershell.log"
            }
            else{
                $logfile = "~\$logname.log"
            }
        }
    }
    process {
        $executionTime = Get-Date -Format "yyyy.MM.dd HH:mm:ss.fff"
        $user = $env:USERNAME
        $domain = $env:USERDNSDOMAIN
        $line = "$executionTime - $($severity.ToUpper().PadLeft(7, " ")) - $($user.ToLower())@$($domain.tolower()) : $logline"
        Out-File -InputObject $line -FilePath $logfile -Encoding utf8 -Append -Width $line.ToCharArray().length -ErrorAction SilentlyContinue
        switch ($severity) {
            "SUCCESS" {
                Write-Host -Object $line -ForegroundColor Green
                break
             }
             "NOTICE" {
                 Write-Host -Object $line -ForegroundColor White
                 break
              }
            "INFO" {
                Write-Host -Object $line -ForegroundColor Cyan
                break
             }
            "WARNING" {
                Write-Host -Object $line -ForegroundColor Yellow
                break
             }
            "ERROR" {
                Write-Host -Object $line -ForegroundColor Red
                break
             }
        }
    }
    end{}
}

# SIG # Begin signature block
# MIITmAYJKoZIhvcNAQcCoIITiTCCE4UCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaJ7/A6X/P5n3xC2vnJ5F3MN6
# FYWgghEFMIIFoTCCBImgAwIBAgITIQAAAA9IvEBUBCwiDgAAAAAADzANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUe+Ms0d+3NBdtonRm2xz46T6eE6cwDQYJKoZI
# hvcNAQEBBQAEggEAL3e8lVuNaboW3t2sZAZ6xlR31lG/ma7GSG64VvyBaFYbb8CZ
# bHHlbBHGOaMdAnnnT/xdldJ1hdvhipoZH1J4OhRwJ8IyGPgrEGxXVk/k+Gad3ztt
# kyveaprMRWhgkksRIrUgOWNVEAGkectupZfdJ1P1i8qz8tEeMiXraAbr4wQ4ijVw
# aIO43EkgR+4TmsI7aQ2VEV/W2M9NN7H/Q1hYApDuq6OVDN1ZyLa3Vj5dHFawNf8g
# xXQXpS72gfHdQKnzFMfmVu4WYy9DRJXucj9jcKtWLNpRzeNQytv9Qp65N+JzNRiC
# 9eyLDFUpi1ICu4YNUn4PxF+1KU3aieoBxtXMIQ==
# SIG # End signature block
