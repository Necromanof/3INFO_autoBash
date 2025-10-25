#!/bin/bash

# Date + préparation du backupFile
date = $(date +%Y%m%d_%H%M%S)
backupFile = "backup-$date.tar.gz" 

# Création du dossier de sauvegarde pour éviter les erreurs
mkdir -p /opt/backups/

# Sauvegarde du fichier
tar -czf /opt/backups/$backupFile /etc /var/www


# Vérification de la sauvegarde du backup
if [ $? -eq 0 ]; then
    echo "Sauvegarde réussie : $backupFile"
else
    echo "Erreur lors de la sauvegarde du fichier $backupFile"
    exit 1
fi

# Supprimer les anciennes sauvegardes au dessus de 7 sauvegardes effectués
ls -t /opt/backups/backup-*.tar.gz | tail -n +8 | xargs rm -f

echo "Sauvegarde terminée"