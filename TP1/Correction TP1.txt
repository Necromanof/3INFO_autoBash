#Exercice 1

#!/bin/bash

BACKUP_DIR="/opt/backups"
LOG_FILE="/var/log/backup.log"
DATE=$(date +%Y%m%d)
BACKUP_FILE="$BACKUP_DIR/backup-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Démarrage de la sauvegarde" >> "$LOG_FILE"
tar -czf "$BACKUP_FILE" /etc /var/www 2>> "$LOG_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Sauvegarde créée : $BACKUP_FILE" >> "$LOG_FILE"

# Supprimer les anciennes sauvegardes (conserver les 7 plus récentes)
ls -1t "$BACKUP_DIR"/backup-*.tar.gz | tail -n +8 | while read old_file; do
    rm -f "$old_file"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Ancienne sauvegarde supprimée : $old_file" >> "$LOG_FILE"
done

#   crontab :  0 2 * * * /path/backup_rotate.sh



#Exercice 2

#!/bin/bash

LOG_FILE="/var/log/healthcheck_nginx.log"
DATE=$(date)

if systemctl is-active --quiet nginx; then
    echo "$DATE - nginx OK" >> "$LOG_FILE"
else
    echo "$DATE - nginx KO - redémarrage..." >> "$LOG_FILE"
    systemctl restart nginx
    echo "$DATE - nginx redémarré" >> "$LOG_FILE"
fi


#   crontab :  */2 * * * * /path/healthcheck_nginx.sh


#Exercice 3
#!/bin/bash

VERSION="$1"
ARCHIVE="/var/www/site-$VERSION.tgz"
DEPLOY_DIR="/var/www/site-$VERSION"
SYMLINK="/var/www/site"
LOG_FILE="/var/log/deploy_site.log"

echo "$(date) - Déploiement version $VERSION" >> "$LOG_FILE"

if [ ! -f "$ARCHIVE" ]; then
    echo "$(date) - Archive $ARCHIVE introuvable" >> "$LOG_FILE"
    exit 1
fi

mkdir -p "$DEPLOY_DIR"
tar -xzf "$ARCHIVE" -C "$DEPLOY_DIR" --strip-components=1

ln -sfn "$DEPLOY_DIR" "$SYMLINK"
systemctl reload nginx

# Vérification avec curl
if curl -s --head http://localhost | grep -q "200 OK"; then
    echo "$(date) - Déploiement réussi" >> "$LOG_FILE"
else
    echo "$(date) - Échec - rollback" >> "$LOG_FILE"
    PREV=$(readlink -f "$SYMLINK")
    rm -rf "$DEPLOY_DIR"
    ln -sfn "$PREV" "$SYMLINK"
    systemctl reload nginx
    echo "$(date) - Rollback vers $PREV effectué" >> "$LOG_FILE"
fi


#   crontab :  5 3 * * * /path/deploy_site.sh VERSION


#Exercice 4

#!/bin/bash

REPORT_DIR="/var/reports"
DATE=$(date +%Y-%m-%d)
REPORT_FILE="$REPORT_DIR/hardening-$DATE.md"
LOG_FILE="/var/log/hardening_audit.log"
SCORE=100

mkdir -p "$REPORT_DIR"

echo "# Rapport de sécurité - $DATE" > "$REPORT_FILE"

# Vérification SSH
if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo "- PasswordAuthentication : OK" >> "$REPORT_FILE"
else
    echo "- PasswordAuthentication : NOK" >> "$REPORT_FILE"
    SCORE=$((SCORE - 30))
fi

if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    echo "- PermitRootLogin : OK" >> "$REPORT_FILE"
else
    echo "- PermitRootLogin : NOK" >> "$REPORT_FILE"
    SCORE=$((SCORE - 30))
fi

# Vérification pare-feu
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    echo "- UFW actif : OK" >> "$REPORT_FILE"
else
    if iptables -L | grep -q "Chain"; then
        echo "- iptables actif : OK" >> "$REPORT_FILE"
    else
        echo "- Pare-feu inactif : NOK" >> "$REPORT_FILE"
        SCORE=$((SCORE - 40))
    fi
fi

echo "- Score final : $SCORE/100" >> "$REPORT_FILE"
echo "$(date) - Audit terminé avec score $SCORE" >> "$LOG_FILE"



#   crontab :  0 7 * * 1 /path/audit.sh