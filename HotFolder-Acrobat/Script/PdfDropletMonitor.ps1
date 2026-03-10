# Get the directory where this script is located (e.g., Project_Root\Script)
$scriptFolder = $PSScriptRoot

# Navigate one level up to the root project folder
$parentFolder = Split-Path -Path $scriptFolder -Parent

# Define relative paths based on the project structure
$dropletPath = Join-Path -Path $scriptFolder -ChildPath "droplet.exe"
$watchFolder = Join-Path -Path $parentFolder -ChildPath "Hot_folder"

# Validate that required directories and files exist
if (-not (Test-Path $watchFolder)) { 
    Write-Error "Watch folder not found: $watchFolder"
    exit 
}
if (-not (Test-Path $dropletPath)) { 
    Write-Error "Acrobat Droplet not found: $dropletPath"
    exit 
}

# Initialize FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchFolder
$watcher.Filter = "*.pdf"
$watcher.EnableRaisingEvents = $true

# Define the action to trigger on new file detection
$action = {
    $filePath = $Event.SourceEventArgs.FullPath
    
    # Wait until the file is completely copied and no longer locked by the OS
    $locked = $true
    $retryCount = 0
    
    while ($locked -and $retryCount -lt 60) {
        try {
            $stream = [System.IO.File]::Open($filePath, 'Open', 'Read', 'None')
            $stream.Close()
            $locked = $false
        } catch {
            Start-Sleep -Seconds 1
            $retryCount++
        }
    }

    # Execute Acrobat Droplet if the file is unlocked and ready
    if (-not $locked) {
        Start-Process -FilePath $dropletPath -ArgumentList "`"$filePath`"" -WindowStyle Hidden -Wait
    }
}

# Register the filesystem event queue to handle multiple files smoothly
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action -SourceIdentifier "PdfDropletMonitor"

Write-Host "Monitoring folder: $watchFolder"
Write-Host "Waiting for PDF files. Do not close this window if you want the automation to run."

# Keep the script running in the background indefinitely
try {
    do {
        Wait-Event -Timeout 1
    } while ($true)
} finally {
    # Cleanup event listeners if the script is terminated
    Unregister-Event -SourceIdentifier "PdfDropletMonitor"
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
}
