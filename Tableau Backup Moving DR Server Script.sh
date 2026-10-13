#!/bin/bash

external_backup_path="/u01/tableau_server/backups"
backup_name="tableau-server-backup"
DR_DATE=`date '+%Y-%m-%d'`
YESTERDAY_DATE=$(date -d "yesterday" +"%Y-%m-%d")
find $external_backup_path  -type f -regex '.*.\(tsbak\|json\)' -mtime +0 -exec sudo rm -rf {} \;
scp -r -o KexAlgorithms=curve25519-sha256@libssh.org $external_backup_path/$backup_name-$DR_DATE.tsbak tdev@Ch3lxmtabas01:/backups/
# END OF SCRIPT
if [ $? -eq 0 ] ; then
echo "Tableau Server Prod Backup copied to DR Server SUCCESS" | mail -s "Tableau Prod Backup copied Success" TableauPowerBIAdmin@equinix.com
echo "Tableau Backup to ch3 server"
else
echo "Tableau Server Prod Backup copied to DR Server FAILED!" | mail -s "Tableau Prod Backup copied failed!" TableauPowerBIAdmin@equinix.com
exit 1
fi