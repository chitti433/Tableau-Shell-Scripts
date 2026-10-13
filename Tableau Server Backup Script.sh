#!/bin/bash

#VARIABLES SECTION
# Set some variables - you should change these to match your own environment

# Set the date how we want it
DATE=`date '+%d-%m-%Y'`
# Grab the current datetime for timestamping the log entries
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
# Do you want to copy your backups to another location after completion?
copy_backup="yes"
# If yes to above, where do you want to copy them?
external_backup_path="/prdbkp/TableauBkp"
# How many days do you want to keep old backup files for?
backup_days="-1"
# What do you want to name your backup files? (will automatically append current date to this filename)
backup_name="tableau-server-backup"
# END OF VARIABLES SECTION

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

# BACKUP SECTION

# get the path to the backups folder
backup_path=$(tsm configuration get -k basefilepath.backuprestore $tsmparams)
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "The path for storing backups is $backup_path"

# count the number of backup files eligible for deletion and output
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Cleaning up old backups..."
lines=$(find $backup_path -type f -regex '.*.\(tsbak\|json\)' -mtime +$backup_days | wc -l)
if [ $lines -eq 0 ]; then
        TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
        echo $TIMESTAMP $lines old backups found, skipping...
else echo  $TIMESTAMP $lines old backups found, deleting...
        #remove backup files older than N days
        find $backup_path -type f -regex '.*.\(tsbak\|json\)' -mtime +$backup_days -exec sudo rm -f {} \;
        find $external_backup_path  -type f -regex '.*.\(tsbak\|json\)' -mtime +$backup_days -exec sudo rm -f {} \;
fi

#export current settings
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Exporting current settings..."
tsm settings export -f $backup_path/settings-$DATE.json $tsmparams
#create current backup
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Backup up Tableau Server data..."
tsm maintenance backup -f $backup_name -d $tsmparams
#copy backups to different location (optional)
DR_DATE=`date '+%Y-%m-%d'`
if [ "$copy_backup" == "yes" ]; then
        TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
        echo $TIMESTAMP "Copying backup and settings to remote share"
        sudo cp -r $backup_path/$backup_name-$DR_DATE.tsbak $external_backup_path/
fi

# END OF BACKUP SECTION
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Backup completed"
# END OF SCRIP
sudo chown -R tableau:tableau $external_backup_path
# DR_DATE=`date '+%Y-%m-%d'`
# scp -r $external_backup_path/$backup_name-$DR_DATE.tsbak tdev@sv2lxtabasbak01:/u01/tableau_server/backups
if [ $? -eq 0 ] ; then
echo "Tableau Server Backup Success" | mail -s "Tableau Prod Backup Success" tableaupowerbiadmin@equinix.com
else
echo "Tableau Server Backup FAILED!" | mail -s "Tableau Prod Backup failed!" tableaupowerbiadmin@equinix.com
exit 1
fi