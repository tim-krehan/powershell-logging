$rootPath = $PSScriptRoot
$moduleName = Get-Item -Path $rootPath |Select-Object -ExpandProperty "Name"

$exportPath = "export"
$classPath = "class"
$internalPath = "internal"
$functionPath = "function"

$export = "$rootPath\{0}" -f $exportPath
$class = "$rootPath\{0}" -f $classPath
$internals = "$rootPath\{0}" -f $internalPath
$functions = "$rootPath\{0}" -f $functionPath

# create Module File
$exportFunctionContent += Get-ChildItem -Path $class |Get-Content
$exportFunctionContent += Get-ChildItem -Path $internals |Get-Content
$exportFunctionContent += Get-ChildItem -Path $functions |Get-Content

$exportModuleFullName = "$export\$moduleName\$moduleName.psm1"
$exportModuleItem = New-Item -Path $exportModuleFullName -Force
Set-Content -Path $exportModuleItem -Value $exportFunctionContent

# create module date file
$manifestData = @{
    Path = "$export\$moduleName\$moduleName.psd1"
    Author = "Tim Krehan"
    CompanyName = "Tim Krehan"
    RootModule = "PoShLogging"
    ModuleVersion = Get-Content "$rootPath\version"
    FunctionsToExport = Get-ChildItem -Path $functions |Select-Object -ExpandProperty "BaseName"
    FormatsToProcess = "PoShLogging.format.ps1xml"
    AliasesToExport = @("ulog")
    ProjectUri = "https://git.brz.de/powershell-modules/poshlogging"
    LicenseUri = "https://git.brz.de/powershell-modules/poshlogging/-/blob/master/LICENSE"
}
New-ModuleManifest @manifestData

# sign exported Module
$signingCertificate = Get-ChildItem cert:\CurrentUser\My -CodeSigningCert -DnsName "Tim Krehan"
Set-AuthenticodeSignature -FilePath $exportModuleItem -Certificate $signingCertificate