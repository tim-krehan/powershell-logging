function Get-LDefaultConfig(){
    return [PSCustomObject]@{
        ModuleName = "PoShLogging"
        UserConfigFolder = "$env:APPDATA\PoShLogging"
    }
}
function Get-LUserConfig(){
    if(Test-Path "$env:APPDATA\PoShLogging\config.json"){
        return Get-Content -Path "$env:APPDATA\PoShLogging\config.json" | ConvertFrom-Json
    }
    else{
        return @{}
    }
}
function Merge-LConfig(){
    $defaultConfig = Get-LDefaultConfig
    $userConfig = Get-LUserConfig
    foreach ($member in ($defaultConfig |Get-Member -MemberType Properties |Select-Object -ExpandProperty "Name")) {
        if($null -eq $userConfig.$member){
            $userConfig |Add-Member -MemberType NoteProperty -Name $member -Value $defaultConfig.$member}
    }
    return $userConfig
}