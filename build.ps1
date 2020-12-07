$rootPath = $PSScriptRoot
$moduleName = Get-Item -Path $rootPath |Select-Object -ExpandProperty "Name"

$exportPath = "export"
$functionPath = "function"

$export = "$rootPath\{0}" -f $exportPath
$functions = "$rootPath\{0}" -f $functionPath

# create Module File
$exportFunctionContent = Get-ChildItem -Path $functions |Get-Content
$exportModuleFullName = "$export\$moduleName\$moduleName.psm1"
$exportModuleItem = New-Item -Path $exportModuleFullName -Force
Set-Content -Path $exportModuleItem -Value $exportFunctionContent

# create module date file
$manifestData = @{
    Path = "$export\$moduleName\$moduleName.psd1"
    Author = "Tim Krehan"
    CompanyName = "Tim Krehan"
    ModuleVersion = Get-Content "$rootPath\version"
    FunctionsToExport = Get-ChildItem -Path $functions |Select-Object -ExpandProperty "BaseName"
    ProjectUri = "https://git.brz.de/powershell-modules/poshlogging"
    LicenseUri = "https://git.brz.de/powershell-modules/poshlogging/-/blob/master/LICENSE"
}
$exportManifestItem = New-ModuleManifest @manifestData

# sign exported Module
$signingCertificate = Get-ChildItem cert:\CurrentUser\My -CodeSigningCert -DnsName "Tim Krehan"
Set-AuthenticodeSignature -FilePath $exportModuleItem -Certificate $signingCertificate