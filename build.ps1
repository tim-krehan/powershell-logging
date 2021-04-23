$rootPath = $PSScriptRoot
$moduleName = Get-Item -Path $rootPath | Select-Object -ExpandProperty "Name"

$export = "$rootPath\export"
$class = "$rootPath\class"
$format = "$rootPath\format"
$internals = "$rootPath\internal"
$functions = "$rootPath\function"

#remove contents of export folder
Remove-Item -Path "$export\*" -Recurse

# create Module File
$exportFunctionContent = Get-ChildItem -Path $class | Get-Content
$exportFunctionContent += Get-ChildItem -Path $internals | Get-Content
$exportFunctionContent += Get-ChildItem -Path $functions | Get-Content

$exportModuleFullName = "$export\$moduleName\$moduleName.psm1"
$exportModuleItem = New-Item -Path $exportModuleFullName -Force
Set-Content -Path $exportModuleItem -Value $exportFunctionContent

# create FormatFile File
Get-ChildItem -Path $format | ForEach-Object -Process {
    $exportFormatFile = $_
    $formatContent = Get-Content -Path $exportFormatFile.FullName
    Set-Content -Path "$export\$moduleName\$($exportFormatFile.BaseName).ps1xml" -Value $formatContent
}
# Set-Content -Path $exportLogFileFormatFullName -Value $exportFormatContent

# create module date file
$manifestData = @{
    Path              = "$export\$moduleName\$moduleName.psd1"
    Author            = "Tim Krehan"
    CompanyName       = "Tim Krehan"
    RootModule        = "PoShLogging"
    ModuleVersion     = Get-Content "$rootPath\version"
    FunctionsToExport = Get-ChildItem -Path $functions | Select-Object -ExpandProperty "BaseName"
    FormatsToProcess  = @(
        "PoShLogging.LogLine.ps1xml"
        "PoShLogging.LogFile.ps1xml"
    )
    PowerShellVersion = "5.1"
    AliasesToExport   = @("ulog", "Connect-Log")
    ProjectUri        = "https://github.com/tim-krehan/powershell-logging/tree/main/export/PoShLogging"
    LicenseUri        = "https://github.com/tim-krehan/powershell-logging/tree/main/export/PoShLogging/-/blob/master/LICENSE"
}
New-ModuleManifest @manifestData

Compress-Archive -Path "$export\$moduleName" -DestinationPath "$export\$moduleName.zip" -Force

Remove-Item -Path "$export\$moduleName" -Recurse -Force

# sign exported Module
# $signingCertificate = Get-ChildItem cert:\CurrentUser\My -CodeSigningCert -DnsName "Tim Krehan"
# Set-AuthenticodeSignature -FilePath $exportModuleItem -Certificate $signingCertificate
# Set-AuthenticodeSignature -FilePath $manifestData.path -Certificate $signingCertificate
# Get-ChildItem -Path "$export\$moduleName\*.ps1xml" |ForEach-Object -Process {
#     $exportFormatFile = $_
#     Set-AuthenticodeSignature -FilePath $exportFormatFile.FullName -Certificate $signingCertificate
# }