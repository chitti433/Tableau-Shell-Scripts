#!/bin/bash

# Grab the current date in YYYY-MM-DD format
DATE=`date +%Y-%m-%d`
# Grab the current datetime for timestamping the log entries
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
# Do you want to copy your archived logs to another location after completion?
copy_logs="yes"
# Where do you want to save your archived logs?
external_log_path="/tableau/backups/log-archives"
# How many days to you want to keep archived log files for?
log_days="2"
# What do you want to name your logs file? (will automatically append current date to this filename)
log_name="logs"

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

# LOGS SECTION

# get the path to the log archive folder
log_path=$(tsm configuration get -k basefilepath.log_archive $tsmparams)
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "The path for storing log archives is $log_path"
# count the number of log files eligible for deletion and output
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Cleaning up old log files..."
lines=$(find $log_path -type f -name '*.zip' ! -newermt "$(date -d '2 days ago' '+%Y-%m-%d')" | wc -l)
if [ $lines -gt 0 ]; then
        echo "$TIMESTAMP $lines found, deleting..."
        #remove log archives older than the specified number of days
        sudo find $log_path -type f -name '*.zip' -exec bash -c 'if [[ $(stat -c %Y "$1") -lt $(date -d "2 days ago" +%s) ]]; then rm -rf "$1"; fi' bash {} \;
        TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
        echo $TIMESTAMP "Cleaning up completed."
else echo TIMESTAMP=$(date '+%Y-%m-%d %H:%MS')
    echo "$TIMESTAMP $lines found, skipping..."
fi

#archive current logs
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Archiving current logs..."
tsm maintenance ziplogs -t -o -f logs-$DATE.zip $tsmparams

#check if the archiving logs is sucessfull
if [ $? -ne 0 ]; then
    echo $TIMESTAMP "Failed to archive the logs"
    exit1
fi

#copy logs to different location (optional)
if [ "$copy_logs" == "yes" ]; then
        TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
        echo $TIMESTAMP "Copying logs to remote share"
fi

# END OF LOGS SECTION

# CLEANUP SECTION

# cleanup old logs and temp files
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Cleaning up Tableau Server..."
tsm maintenance cleanup -a $tsmparams
echo $TIMESTAMP "Cleaning Completed"

# END OF SCRIPT
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Housekeeping completed"