#!/bin/bash

# Dates et chemins
DATE=$(date +%F)           
FILEDATE=$(date +%Y%m%d)  
REPORT_DIR=/var/reports
REPORT_FILE="$REPORT_DIR/sys_audit-$FILEDATE.txt"

#Création du fichier si besoin
if [ ! -d "$REPORT_DIR" ]; then
  mkdir -p "$REPORT_DIR" || { echo "Failed to create $REPORT_DIR"; exit 1; }
  chmod 755 "$REPORT_DIR"
fi

#Utilisation du disque en root /
disk_percent=$(df -h / | awk 'NR==2 {print $5}')
disk_used=$(df -h / | awk 'NR==2 {print $3}')
disk_total=$(df -h / | awk 'NR==2 {print $2}')
disk_line="Disk usage : $disk_percent used ($disk_used/$disk_total)"

#Mémoire libre en MB 
mem_free=$(free -m | awk '/^Mem:/ {print $4}')
free_line="Free memory: ${mem_free} MB"

#Vérification des services
ssh_status="inactive"
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
    ssh_status="active"
  fi
elif command -v service >/dev/null 2>&1; then
  if service ssh status >/dev/null 2>&1 || service sshd status >/dev/null 2>&1; then
    ssh_status="active"
  fi
else
  if pgrep -x sshd >/dev/null 2>&1 || pgrep -x ssh >/dev/null 2>&1; then
    ssh_status="active"
  fi
fi
ssh_line="SSH service : $ssh_status"

# Style du header
header="=== System Audit Report - $DATE ==="
completed_line="Audit completed at $(date +%H:%M)"

echo "$header"
echo "$disk_line"
echo "$free_line"
echo "$ssh_line"
echo "$completed_line"

#Repport dans le fichier rapport
{
  echo "$header"
  echo "$disk_line"
  echo "$free_line"
  echo "$ssh_line"
  echo ""
  echo "$completed_line"
} > "$REPORT_FILE"

chmod 644 "$REPORT_FILE"
