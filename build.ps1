$rootPath = $PSScriptRoot
$moduleName = Get-Item -Path $rootPath |Select-Object -ExpandProperty "Name"

$exportPath = "export"
$classPath = "class"
$formatPath = "format"
$internalPath = "internal"
$functionPath = "function"

$export = "$rootPath\{0}" -f $exportPath
$class = "$rootPath\{0}" -f $classPath
$format = "$rootPath\{0}" -f $formatPath
$internals = "$rootPath\{0}" -f $internalPath
$functions = "$rootPath\{0}" -f $functionPath

#remove contents of export folder
Remove-Item -Path "$export\*" -Recurse

# create Module File
$exportFunctionContent = Get-ChildItem -Path $class |Get-Content
$exportFunctionContent += Get-ChildItem -Path $internals |Get-Content
$exportFunctionContent += Get-ChildItem -Path $functions |Get-Content

$exportModuleFullName = "$export\$moduleName\$moduleName.psm1"
$exportModuleItem = New-Item -Path $exportModuleFullName -Force
Set-Content -Path $exportModuleItem -Value $exportFunctionContent

# create FormatFile File
Get-ChildItem -Path $format |ForEach-Object -Process {
    $exportFormatFile = $_
    $formatContent = Get-Content -Path $exportFormatFile.FullName
    Set-Content -Path "$export\$moduleName\$($exportFormatFile.BaseName).ps1xml" -Value $formatContent
}
# Set-Content -Path $exportLogFileFormatFullName -Value $exportFormatContent

# create module date file
$manifestData = @{
    Path = "$export\$moduleName\$moduleName.psd1"
    Author = "Tim Krehan"
    CompanyName = "Tim Krehan"
    RootModule = "PoShLogging"
    ModuleVersion = Get-Content "$rootPath\version"
    FunctionsToExport = Get-ChildItem -Path $functions |Select-Object -ExpandProperty "BaseName"
    FormatsToProcess = @(
        "PoShLogging.LogLine.ps1xml"
        # "PoShLogging.LogBook.ps1xml"
    )
    AliasesToExport = @("ulog")
    ProjectUri = "https://git.brz.de/powershell-modules/poshlogging"
    LicenseUri = "https://git.brz.de/powershell-modules/poshlogging/-/blob/master/LICENSE"
}
New-ModuleManifest @manifestData

# sign exported Module
$signingCertificate = Get-ChildItem cert:\CurrentUser\My -CodeSigningCert -DnsName "Tim Krehan"
Set-AuthenticodeSignature -FilePath $exportModuleItem -Certificate $signingCertificate
Set-AuthenticodeSignature -FilePath $manifestData.path -Certificate $signingCertificate