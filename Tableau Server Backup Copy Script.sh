external_backup_path="/prdbkp/TableauBkp"
backup_name="tableau-server-backup"
DR_DATE=`date '+%Y-%m-%d'`
sudo chown -R tableau:tableau $external_backup_path

scp -r -o KexAlgorithms=curve25519-sha256@libssh.org $external_backup_path/$backup_name-$DR_DATE.tsbak tdev@sv2lxtabasbak01:/u01/tableau_server/backups

# END OF SCRIP
if [ $? -eq 0 ] ; then
echo "Tableau Server Prod Backup copied to Backup Server SUCCESS" | mail -s "Tableau Prod Backup copied Success" tableaupowerbiadmin@equinix.com
else
echo "Tableau Server Prod Backup copied to Backup Server FAILED!" | mail -s "Tableau Prod Backup copied failed!" tableaupowerbiadmin@equinix.com