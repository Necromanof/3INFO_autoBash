# Récupérer les infos du disque C:
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
if (-not $disk) {
    Write-Error "Disk C: not found"
    exit 1
}

$total = [int64]($disk.Size)
$free  = [int64]($disk.FreeSpace)

# Calculs
$usedPercent = 0
if ($total -gt 0) {
    $usedPercent = [math]::Round((($total - $free) / $total) * 100)
}
$freeGB  = [math]::Round($free / 1GB)
$totalGB = [math]::Round($total / 1GB)

#Fichier des logs
$logDir  = 'C:\Logs'
$logFile = Join-Path $logDir 'diskcheck.log'
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

#Formule du message
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$message = "$timestamp - C: $usedPercent% utilise ($freeGB Go libres sur $totalGB Go)"

# Alerte et affichage console
if ($usedPercent -ge 80) {
    $message += ' - ALERTE'
    Write-Host $message
} else {
    Write-Host $message
}

#Ajout des infos dans le fichier log
Add-Content -Path $logFile -Value $message
