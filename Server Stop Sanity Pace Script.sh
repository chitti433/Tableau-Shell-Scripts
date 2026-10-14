#!/bin/bash
#Script to backup Tableau Server
#Author : Rajesh Kothuru
# Load the Tableau Server environment variables into the cron environment
source /etc/profile.d/tableau_server.sh
tsm_status=$(tsm status)
current_time=$(date "+%Y.%m.%d")
exec >/u01/app/scripts/logs/DR_Stop_sanity_$current_time.txt 2>&1

echo `date` - "SCRIPT - STARTED"
echo `date` - $1" - SANITY_STS - STARTED"

if [[ $tsm_status == *"STOPPED"* ]]; then
        echo `date` - $1" - SANITY_STS - COMPLETED"
        else
        echo `date` - $1" - SANITY_STS - FAILED"
        fi
echo `date` - "SCRIPT - COMPLETED"