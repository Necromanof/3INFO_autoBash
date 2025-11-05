## Exercice 1 


$ErrorActionPreference = "Stop"

$backupRoot = "C:\Backups"
$logFile    = "C:\Logs\backup.log"
$paths      = @(
    "C:\Windows\System32\drivers\etc",
    "C:\inetpub\wwwroot"
) | Where-Object { Test-Path $_ }

# Création des dossiers si nécessaire
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null

$today      = Get-Date -Format "yyyyMMdd"
$backupFile = Join-Path $backupRoot "backup-$today.zip"

try {
    Add-Content $logFile "$(Get-Date -Format s) - Début sauvegarde -> $backupFile"

    if (Test-Path $backupFile) {
        Remove-Item $backupFile -Force
    }

    Compress-Archive -Path $paths -DestinationPath $backupFile -Force

    # Rotation : on garde uniquement les 7 plus récents
    $archives = Get-ChildItem $backupRoot -Filter "backup-*.zip" |
                Sort-Object LastWriteTime -Descending

    if ($archives.Count -gt 7) {
        $toDelete = $archives | Select-Object -Skip 7
        foreach ($a in $toDelete) {
            Add-Content $logFile "$(Get-Date -Format s) - Suppression ancienne sauvegarde : $($a.FullName)"
            Remove-Item $a.FullName -Force
        }
    }

    Add-Content $logFile "$(Get-Date -Format s) - Sauvegarde OK"
}
catch {
    Add-Content $logFile "$(Get-Date -Format s) - ERREUR : $($_.Exception.Message)"
    exit 1
}


## Exercice 2 

##-----------------------------------------------------------------------------------------------------------------------------------------------------------------


param(
    [string]$ServiceName = "Spooler"
)

$logFile = "C:\Logs\svc-health.log"
New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null

$timestamp = Get-Date -Format s

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $svc) {
    Add-Content $logFile "$timestamp - Service '$ServiceName' introuvable"
    exit 1
}

if ($svc.Status -ne "Running") {
    Add-Content $logFile "$timestamp - $ServiceName arrêté, tentative de démarrage…"
    try {
        Start-Service -Name $ServiceName -ErrorAction Stop
        Add-Content $logFile "$(Get-Date -Format s) - $ServiceName démarré avec succès"
    }
    catch {
        Add-Content $logFile "$(Get-Date -Format s) - ERREUR démarrage $ServiceName : $($_.Exception.Message)"
    }
}
else {
    Add-Content $logFile "$timestamp - Service OK ($ServiceName en cours d’exécution)"
}


##-----------------------------------------------------------------------------------------------------------------------------------------------------------------

## Exercice 3


param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

$webRoot        = "C:\inetpub\wwwroot"
$webBase        = "C:\Web"
$zipPath        = Join-Path $webBase "site-$Version.zip"
$deployDir      = Join-Path $webBase "site-$Version"
$backupDir      = Join-Path $webBase "backup-wwwroot"
$logFile        = "C:\Logs\deploy-iis.log"
$siteUrl        = "http://localhost/"

New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null

function Write-Log($msg) {
    Add-Content $logFile "$(Get-Date -Format s) - $msg"
}

try {
    Write-Log "=== Déploiement version $Version ==="

    if (-not (Test-Path $zipPath)) {
        throw "Archive introuvable : $zipPath"
    }

    # Sauvegarde version actuelle
    if (Test-Path $backupDir) {
        Remove-Item $backupDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    if (Test-Path $webRoot) {
        Write-Log "Backup de $webRoot vers $backupDir"
        Copy-Item "$webRoot\*" $backupDir -Recurse -Force
    }

    # Extraction de la nouvelle version
    if (Test-Path $deployDir) {
        Remove-Item $deployDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $deployDir -Force | Out-Null

    Write-Log "Extraction de $zipPath vers $deployDir"
    Expand-Archive -Path $zipPath -DestinationPath $deployDir -Force

    # Remplacement du contenu de wwwroot
    if (Test-Path $webRoot) {
        Write-Log "Nettoyage de $webRoot"
        Get-ChildItem $webRoot -Force | Remove-Item -Recurse -Force
    }
    else {
        New-Item -ItemType Directory -Path $webRoot -Force | Out-Null
    }

    Write-Log "Copie de la nouvelle version dans $webRoot"
    Copy-Item "$deployDir\*" $webRoot -Recurse -Force

    # Redémarrage IIS
    Write-Log "Redémarrage du service W3SVC"
    Restart-Service -Name W3SVC -Force

    # Vérification du site
    Write-Log "Vérification fonctionnelle via $siteUrl"
    $response = Invoke-WebRequest -Uri $siteUrl -UseBasicParsing -TimeoutSec 10

    if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
        Write-Log "Déploiement OK (StatusCode = $($response.StatusCode))"
    }
    else {
        throw "Code HTTP inattendu : $($response.StatusCode)"
    }
}
catch {
    Write-Log "ERREUR : $($_.Exception.Message)"
    Write-Log "Restauration de la version précédente..."

    # Rollback
    if (Test-Path $backupDir) {
        Get-ChildItem $webRoot -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item "$backupDir\*" $webRoot -Recurse -Force
        Write-Log "Rollback terminé."
    }
    else {
        Write-Log "Aucun backup disponible pour rollback."
    }

    exit 1
}



##-----------------------------------------------------------------------------------------------------------------------------------------------------------------

## Exercice 4

$ErrorActionPreference = "Stop"

$reportDir  = "C:\Reports"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

$today      = Get-Date -Format "yyyy-MM-dd"
$reportFile = Join-Path $reportDir "hardening-$today.txt"

$results = [ordered]@{}

# 1) Pare-feu activé pour les 3 profils
try {
    $profiles = Get-NetFirewallProfile -Profile Domain,Private,Public
    $allEnabled = $profiles | Where-Object { -not $_.Enabled } | Measure-Object
    $firewallOK = ($allEnabled.Count -eq 0)
    $results["Firewall"] = $firewallOK
}
catch {
    $results["Firewall"] = $false
}

# 2) RDP désactivé : fDenyTSConnections = 1
try {
    $rdpKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    $value  = (Get-ItemProperty -Path $rdpKey -Name "fDenyTSConnections").fDenyTSConnections
    $rdpOK  = ($value -eq 1)
    $results["RDP désactivé"] = $rdpOK
}
catch {
    $results["RDP désactivé"] = $false
}

# 3) RemoteRegistry arrêté
try {
    $svc = Get-Service -Name "RemoteRegistry" -ErrorAction Stop
    $remoteRegOK = ($svc.Status -eq "Stopped")
    $results["RemoteRegistry arrêté"] = $remoteRegOK
}
catch {
    $results["RemoteRegistry arrêté"] = $true  # s'il n'existe pas, on considère OK
}

# Calcul du score (3 règles : 34 + 33 + 33 = 100)
$score = 0
if ($results["Firewall"])             { $score += 34 }
if ($results["RDP désactivé"])        { $score += 33 }
if ($results["RemoteRegistry arrêté"]){ $score += 33 }

# Génération du rapport
$lines = @()
$lines += "Rapport de hardening - $today"
$lines += "---------------------------------------"
$lines += "Score global : $score / 100"
$lines += ""

foreach ($k in $results.Keys) {
    $status = if ($results[$k]) { "OK" } else { "NON CONFORME" }
    $lines += ("{0} : {1}" -f $k, $status)
}

$lines | Set-Content -Path $reportFile -Encoding UTF8
Write-Host "Rapport généré : $reportFile"
