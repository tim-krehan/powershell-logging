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
        $configFolder =  "$env:APPDATA\$((Get-DefaultParameter).ModuleName)"
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