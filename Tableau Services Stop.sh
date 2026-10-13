#!/bin/bash
#Script to backup Tableau Server
#Author : Chandra Sekhar
#Version : Draft 1.1
#       HOW TO USE THIS SCRIPT:
#               Run the setup script to fetch the script and install it in your system correctly
#
#               Test that the script works in your environment by running it manually
#                       You must execute the script as a user that is a member of the tsmadmin group
#                       sudo su -l <tsmusername> -c /var/opt/tableau/tableau_server/scripts/tableau-server-housekeeping.sh <tsmusername> <tsmpassword>
#
#               NOTE you have to add your tsm username and password at the end of the command to execute the script.
#                       This avoids you having to hardcode credentials into the script itself
#
current_time=$(date "+%Y.%m.%d")
exec >/u01/scripts/tsmRestart/logs/ospatchstop_$current_time.txt 2>&1
now=`date`
echo "$now"
#VARIABLES SECTION
# Set some variables - you should change these to match your own environment

Stop="yes"
Status="yes"
#tsmstatus ='tsm status $tsmparams'

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

# STOP SECTION

# stop the server (optional, uncomment to run)
        echo `date` - $1" - SHUTDOWN_STS - STARTED "
        tsm stop $tsmparams
                echo `date` - $1" - SHUTDOWN_STS - COMPLETED "
                # END OF STOP SECTION
# STATUS SECTION

# check the server status
         echo "Checking Tableau Server Status"
                 tsm status $tsmparams
        if [[ $tsmstatus -eq "STOPED" ]];
        then
        echo "Server Is STOPED"
        else
        echo "Server Is DEGRADED"
        fi


# END OF STATUS SECTION

# END OF SCRIPT
echo `date`  "Stopped Tableau Server"