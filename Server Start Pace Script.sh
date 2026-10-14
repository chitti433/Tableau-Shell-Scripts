#!/bin/bash
#Script to start Tableau Server
#Author : Rajesh Kothuru
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

exec >/u01/app/scripts/logs/DR_start_$current_time.txt 2>&1
now=`date`
echo "$now"

#VARIABLES SECTION
# Set some variables - you should change these to match your own environment

START="yes"
Status="yes"


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

# START SECTION

# START the server (optional, uncomment to run)
        echo `date` - "SCRIPT - STARTED"
        echo `date` - $1" - STARTUP_STS - STARTED "
        tsm start $tsmparams

# END OF START SECTION
# STATUS SECTION

# check the server status after stopping
tsm_status=$(tsm status)

# check the server status
         if [[ $tsm_status == *"RUNNING"* ]]; then
         echo `date` - $1" - STARTUP_STS - COMPLETED"
         else
         echo `date` - $1" - STARTUP_STS - FAILED"
         fi
echo `date` - "SCRIPT - COMPLETED"