$ErrorActionPreference = "Stop"
$rootPath = Resolve-Path -Path "."
$fileOrder = @{
    "modules" = @(
        "class"
        "internal"
        "function"
    )
    # "scripts" = @(
    #     "script"
    # )
}

#create taget path
Write-Host "Processing Modules"
$targetDirectory = Join-Path -Path $rootPath -ChildPath "build"
Write-Host "Target Directory will be $targetDirectory"
if (Test-Path -Path $targetDirectory) {
    Write-Host "Directory will be removed."
    Remove-Item -Path $targetDirectory -Recurse -Force
}

$targetDirectory = New-Item -Path $targetDirectory -ItemType Directory

$fileOrder.Keys | ForEach-Object -Process {
    $_type = $_
    $_fileOrder = $fileOrder.$_type

    $targetModuleBuildDirectory = Join-Path -Path $targetDirectory -ChildPath $_type
    $targetModuleBuildDirectory = New-Item -Path $targetModuleBuildDirectory -ItemType Directory
    
    $moduleFolder = Join-Path -Path $rootPath -ChildPath $_type
    $foundModules = Get-ChildItem -Path $moduleFolder -Directory -Recurse:$false
    Write-Host "Found $($foundModules |Measure-Object |Select-Object -ExpandProperty Count) $_type"
    $foundModules | ForEach-Object -Process {
        #region get metadata data
        $_modulePath = $_
        $_moduleName = $_modulePath.BaseName
        $metaDataFile = Join-Path -Path $_modulePath.FullName -ChildPath "metadata.json"
        $metaData = Get-Content -Path $metaDataFile | ConvertFrom-Json
        #endregion
    
        #region create folder structure
        Write-Host "##[group]$_moduleName"
        $targetModuleDirectory = Join-Path -Path $targetModuleBuildDirectory -ChildPath $_moduleName
        $targetModuleDirectory = New-Item -Path $targetModuleDirectory -ItemType Directory
        $targetModuleDirectory = Join-Path -Path $targetModuleDirectory.FullName -ChildPath $metaData.version
        $targetModuleDirectory = New-Item -Path $targetModuleDirectory -ItemType Directory
        #endregion

        switch ($_type) {
            "modules" {
                #region create Module File
                Write-Host "##[section]Module File"
                $exportFunctionContent = [string]::Empty
                $_fileOrder | ForEach-Object -Process {
                    $_folderName = $_
                    $contentFolder = Join-Path -Path $_modulePath.FullName -ChildPath $_folderName
                    if (Test-Path -Path $contentFolder) {
                        Write-Host "including $_folderName"
                        $exportFunctionContent += Get-ChildItem -Path $contentFolder | ForEach-Object -Process {
                            Write-Host "##[debug]$($_.BaseName)"
                            return $_
                        } | Get-Content -Raw
                        $exportFunctionContent += [Environment]::NewLine
                    }
                }
                $exportModuleItem = New-Item -Path $targetModuleDirectory -Force -Name "$_moduleName.psm1"
                Write-Host "Creating `"$($exportModuleItem.Name)`""
                Set-Content -Path $exportModuleItem -Value $exportFunctionContent
                #endregion
                
                #region create FormatFile File
                Write-Host "##[section]Format File"
                $FormatsToProcess = @()
                $contentFolder = Join-Path -Path $_modulePath.FullName -ChildPath "format"
                if (Test-Path -Path $contentFolder) {
                    Write-Host "including format"
                    $formatFiles = Get-ChildItem -Path $contentFolder
                    $formatFiles | ForEach-Object -Process {
                        $_formatFile = $_
                        Write-Host "##[debug]$($_formatFile.BaseName)"
                        $FormatsToProcess += $_formatFile
                        $formatName = $_formatFile.BaseName
                        $exportFormatContent = Get-Content -Raw -Path $_formatFile.FullName
                        $exportFormatItem = New-Item -Path $targetModuleDirectory -Force -Name "$($formatName).ps1xml"
                        Set-Content -Path $exportFormatItem -Value $exportFormatContent
                        Write-Host "Creating `"$($exportFormatItem.Name)`""
                    }
                }
                #endregion
            
                #region create module data file
                Write-Host "##[section]Manifest File"
                $manifestData = @{
                    Path               = Join-Path -Path $targetModuleDirectory -ChildPath "$_moduleName.psd1"
                    Author             = $metaData.author
                    CompanyName        = "Tim Krehan"
                    Description        = $metaData.description
                    RootModule         = $_moduleName
                    ModuleVersion      = $metaData.version
                    FunctionsToExport  = Get-ChildItem -Path (Join-Path -Path $_modulePath.FullName -ChildPath "function") | Select-Object -ExpandProperty "BaseName"
                    FormatsToProcess   = $FormatsToProcess.Name
                    RequiredModules    = @(
                        $metaData.dependencies.modules
                    )
                    RequiredAssemblies = @(
                        $metaData.dependencies.assemblies
                    )
                    PowerShellVersion  = $metaData.powershellversion
                    AliasesToExport    = $metadata.aliasesToExport
                    ProjectUri         = 'https://github.com/tim-krehan/powershell-logging'
                    LicenseUri         = 'https://github.com/tim-krehan/powershell-logging/tree/main/export/PoShLogging/-/blob/master/LICENSE'
                    PrivateData  = @{
                        Tags         = $metaData.tags
                        ReleaseNotes = $metaData.releasemessage
                    }
                }
                Write-Host "Creating Manifest File"
                New-ModuleManifest @manifestData
                #endregion
                break;
            }
            "scripts" {
                #region create Module File
                Write-Host "##[section]Script File"
                $_fileOrder | ForEach-Object -Process {
                    $_folderName = $_
                    Write-Host "including $_foldername"
                    $_scriptPath = Join-Path -Path $_modulePath.FullName -ChildPath $_folderName
                    Get-ChildItem -Path $_scriptPath -Recurse | ForEach-Object -Process {
                        $_exportFile = $_
                        $relativeDestination = $_exportFile.FullName -replace [regex]::Escape((Join-Path -Path $_modulePath.FullName -ChildPath $_folderName)), ""
                        Write-Host "##[debug]$relativeDestination"
                        Copy-Item -Path $_exportFile.FullName -Destination (Join-Path -Path $targetModuleDirectory.FullName -ChildPath $relativeDestination)
                    }
                }
                #endregion

                #region appending script information to main.ps1
                Write-Host "##[section]appending script information to main.ps1"
                $scriptMainFile = Get-ChildItem -Path (Join-Path -Path $targetModuleDirectory.FullName -ChildPath "main.ps1")
                $scriptMainFileContent = $scriptMainFile |Get-Content
                $ScriptSplat = @{
                    PassThru     = $true
                    Version      = $metadata.version
                    Author       = $metadata.author
                    Description  = $metadata.description
                    Tags         = $metadata.tags
                    ReleaseNotes = $metadata.releasemessage
                    Copyright    = "Copyright ©$(Get-Date -Format "yyyy") $($metadata.author)"
                    ProjectUri   = 'https://github.com/tim-krehan/powershell-logging'
                    LicenseUri   = 'https://github.com/tim-krehan/powershell-logging/blob/main/LICENSE'
                    PrivateData  = @{
                        Tags         = $metaData.tags
                        ReleaseNotes = $metaData.releasemessage
                    }
                }
                if ($metadata.dependencies.modules.Count -gt 0) {
                    $ScriptSplat.RequiredModules = @()
                    $metaData.dependencies.modules |ForEach-Object -Process {
                        $_requiredModule = $_
                        if($_requiredModule -is [string]){
                            $ScriptSplat.RequiredModules += $_requiredModule
                        }
                        elseif($_requiredModule -is [PSCustomObject]){
                            $htRequiredModule = @{}
                            $_requiredModule.PSObject.Properties |ForEach-Object -Process {
                                $htRequiredModule[$_.Name] = $_.Value
                            }
                            $ScriptSplat.RequiredModules += $htRequiredModule
                        }
                    }
                }
                if ($metadata.dependencies.scripts.Count -gt 0) {
                    $ScriptSplat.RequiredScripts = $metadata.dependencies.scripts
                }
                $ScriptInfo = (New-ScriptFileInfo @ScriptSplat) -replace "param\(\)", ""
                Out-File -FilePath $scriptMainFile.FullName -Force -InputObject $ScriptInfo
                Out-File -FilePath $scriptMainFile.FullName -Force -InputObject $scriptMainFileContent -Append 
                #endregion
                break;
            }
        }
    
        Write-Host "##[endgroup]module `"$_moduleName`" done"
    }
}