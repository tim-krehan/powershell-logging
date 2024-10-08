Class LogTargetFile : LogTarget {
  [System.IO.FileSystemInfo]$fileInformation
  LogTargetFile($filePath) : base([LogTargetType]::File) {
    if(Test-Path -Path $filePath){
      $this.fileInformation = Get-Item -Path $filePath -ErrorAction Stop
    }
    else{ 
      $this.fileInformation = New-Item -Path $filePath -ItemType File -Force -ErrorAction Stop
    }
  }

  Set([LogLine[]]$logLines) {
    $this.checkState()
    $newContent = $logLines | ForEach-Object -Process { $_.ToString() }
    $joinedContent = $newContent -join [Environment]::NewLine
    try {
      Out-File -InputObject $joinedContent -Append -FilePath $this.fileInformation.FullName -Encoding utf8
    }
    catch {
      throw "Error Saving File"
    }
  }

  [LogLine[]] Get() {
    $this.checkState()
    $availableContent = (Get-Content -Encoding UTF8 -Path $this.fileInformation.FullName) -split [Environment]::NewLine
    $returnedLines = @()
    foreach ($line in $availableContent) {
      $newline = [LogLine]::new($line)
      $newline.Saved = $true
      $returnedLines += $newline
    }
    return $returnedLines
  }

  Rename($newName) {
    $this.checkState()
    $dest = Rename-Item -Path $this.fileInformation.FullName -NewName $newName -PassThru
    $this.fileInformation = $dest
  }

  Move($newLocation) {
    $this.checkState()
    if (Test-Path -Path $newLocation) {
      $newLocationItem = Get-Item -Path $newLocation
      if ($newLocationItem -is [System.IO.DirectoryInfo]) {
        $dest = Move-Item -Path $this.fileInformation.FullName -Destination $newLocation -PassThru
        $this.fileInformation = $dest
      }
      else {
        throw "destination needs to be a folder"
      }
    }
    else {
      throw "folder '$newLocation' not existant"
    }
  }

  Clear() {
    New-Item -Path $this.fileInformation.FullName -ItemType File -Force
  }
}
