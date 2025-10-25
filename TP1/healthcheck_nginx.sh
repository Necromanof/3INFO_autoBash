#!/bin/bash

log = "/var/log/healthcheck_nginx.log"
date = $(date '+%Y-%m-%d %H:%M:%S')

# Vérification du focntionnement de nginx
systemctl is-active nginx > /dev/null 2>&1

# Redémarrage de nginx si inactif
if [ $? -ne 0 ]; then
    echo "[$date] Nginx est inactif, redémarrage en cours !" >> $log
    systemctl restart nginx

    if [ $? -eq 0 ]; then
        echo "$date - Nginx a été redémarré." >> $log
    else
        echo "$date - Échec du redémarrage de Nginx." >> $log
    fi
    
else
    echo "$date - Nginx est de retour !" >> $log
fi