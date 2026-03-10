# Get the directory where this script is located
$scriptFolder = $PSScriptRoot
$parentFolder = Split-Path -Path $scriptFolder -Parent

# Define relative paths
$dropletPath = Join-Path -Path $scriptFolder -ChildPath "droplet.exe"
$watchFolder = Join-Path -Path $parentFolder -ChildPath "Hot_folder"

if (-not (Test-Path $watchFolder)) { Write-Error "Watch folder not found: $watchFolder"; exit }
if (-not (Test-Path $dropletPath)) { Write-Error "Acrobat Droplet not found: $dropletPath"; exit }

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchFolder
$watcher.Filter = "*.pdf"
$watcher.EnableRaisingEvents = $true

$action = {
    $filePath = $Event.SourceEventArgs.FullPath
    $droplet = $Event.MessageData # Retrieving the droplet path safely from Event context
    
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] New file detected: $(Split-Path $filePath -Leaf)"
    
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

    if (-not $locked) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] File unlocked. Sending to Acrobat Droplet..."
        try {
            Start-Process -FilePath $droplet -ArgumentList "`"$filePath`"" -WindowStyle Hidden -Wait
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Acrobat Droplet finished processing."
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ERROR starting Droplet: $_"
        }
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ERROR: File was locked for too long."
    }
}

# Clear old events if restarting the script, then register the new one and hide the confusing table
Unregister-Event -SourceIdentifier "PdfDropletMonitor" -ErrorAction SilentlyContinue
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action -SourceIdentifier "PdfDropletMonitor" -MessageData $dropletPath | Out-Null

Write-Host "Monitoring folder: $watchFolder"
Write-Host "Waiting for PDF files. Drop a NEW file into the Hot_folder to test it."

try {
    do { Wait-Event -Timeout 1 } while ($true)
} finally {
    Unregister-Event -SourceIdentifier "PdfDropletMonitor" -ErrorAction SilentlyContinue
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
}
