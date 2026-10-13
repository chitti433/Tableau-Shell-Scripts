#!/bin/bash

# LOAD ENVIRONMENT & USER INPUT

# Load the Tableau Server environment variables into the cron environment
source /etc/profile.d/tableau_server.sh

# In case that doesn't work then this might do it
load_environment_file() {
  if [[ -f /etc/opt/tableau/tableau_server/environment.bash ]]; then
    source /etc/opt/tableau/tableau_server/environment.bash
    env_file_exists=1
  fi
}

if [ "$#" -eq 2 ] ; then
        # Get tsm username from command line input
        tsmuser="$1"
        # Get tsm password from command line input
        tsmpassword="$2"
        tsmparams="-u $tsmuser -p $tsmpassword"
elif [ $(echo $TABLEAU_SERVER_DATA_DIR_VERSION | cut -d. -f1) -ge 20192 ]  && (id -nG | grep -q tsmadmin || [ ${EUID} -eq 0 ]) ; then
        # 2019.2 workflow. If running as tsmadmin member or root, do not set userinfo
        declare tsmparams
fi

external_backup_path="/backups"
backup_name="tableau-server-backup"
DR_DATE=`date '+%Y-%m-%d'`
tableau_backup="/u01/app/tableau/data/tabsvc/files/backups"
find $tableau_backup  -type f -regex '.*.\(tsbak\|json\)' -mtime +1 -exec sudo rm -rf {} \;
find $external_backup_path  -type f -regex '.*.\(tsbak\|json\)' -mtime +1 -exec sudo rm -rf {} \;

sudo chown -R tableau:tableau $external_backup_path/$backup_name-$DR_DATE.tsbak
sudo chmod -R 775 $external_backup_path/$backup_name-$DR_DATE.tsbak

tsm stop $tsmparams
tsm maintenance cleanup -a $tsmparams
tsm maintenance restore -f $backup_name-$DR_DATE.tsbak $tsmparams

if [ $? -eq 0 ] ; then
echo "Tableau DR Server Restore Success" | mail -s "Tableau DR Restore Success" TableauPowerBIAdmin@equinix.com
else
echo "Tableau DR Server Restore FAILED!" | mail -s "Tableau DR Restore failed!" TableauPowerBIAdmin@equinix.com
exit 1
fi