#!/bin/bash

TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`

# LOAD ENVIRONMENT&USER INPUT

# Load the Tableau Server environment variables into the cron environment
source /etc/profile.d/tableau_server.sh

# In case that doesn't work then this might do it
load_environment_file() {
  if [[ -f /etc/opt/tableau/tableau_server/environment.bash ]]; then
    source /etc/opt/tableau/tableau_server/environment.bash
    env_file_exists=1
  fi
}

if [ "$#" -eq 2 ]; then
    # Get tsm username from command line input
    tsmuser="$1"
    # Get tsm password from command line input
    tsmpassword="$2"
    tsmparams="-u $tsmuser -p $tsmpassword"
elif [ $(echo $TABLEAU_SERVER_DATA_DIR_VERSION | cut -d. -f1) -ge 20192 ] && (id -nG | grep -q tsmadmin || [ ${EUID} -eq 0 ]); then
    # 2019.2 workflow. If running as tsmadmin member or root, do not set userinfo
    declare tsmparams
fi

# Define the path to the backgrounder logs
LOG_PATH="/u01/app/tableau/data/tabsvc/logs/backgrounder"

# Define the specific log files to check
LOG_FILES=("backgrounder_node7-0.log" "backgrounder_node7-1.log" "backgrounder_node7-2.log" "backgrounder_node7-3.log" "backgrounder_node7-4.log" "backgrounder_node7-5.log" "backgrounder_node7-6.log" "backgrounder_node7-7.log")

# Get the current time and calculate the time 5 minutes ago
current_time=$(date +%s)
five_minute_ago=$(($current_time - 300))

# Loop through each specified log file
for log_file in "${LOG_FILES[@]}"; do
    full_log_path="$LOG_PATH/$log_file"

    echo $TIMESTAMP "Processing log file: $full_log_path"

    # Check if the log file exists
    if [[ ! -f "$full_log_path" ]]; then
        echo "Log file $full_log_path does not exist."
        continue
    fi
# Use grep to filter for the specific event and check timestamps
 grep "event=hyperEngineWrapper.refreshExtracts.error" "$full_log_path" | while read -r line; do
        # Extract the timestamp from the log line
        timestamp=$(echo "$line" | awk '{print $1 " " $2}')
        # Convert timestamp to seconds since epoch
        log_time=$(date -d "$timestamp" +%s)

        # Check if the log time is within the last 5 minutes
        if [[ $log_time -ge $five_minute_ago ]]; then
            contentName=$(echo "$line" | grep -o 'contentName="[^"]*"' | cut -d'"' -f2)
            contentType=$(echo "$line" | grep -o 'contentType=[^ ]*' | cut -d'=' -f2)
            errorMessage=$(echo "$line" | grep -o 'errorMessage="[^"]*"' | cut -d'"' -f2)
            echo -e "Error Message: ${errorMessage}\n\nContent Name: ${contentName}\nContent Type: ${contentType} \n\n${line} \n\n Extract Refresh Failed for $contentName in $full_log_path" | mail -s "Extract Refresh Failed in sv2lxtabas07 server" TableauPowerBIAdmin@equinix.com,Incorta_Obiee_admins@equinix.com
               if [[ "$errorMessage" == *"The Google BigQuery service experienced an unknown internal error. Please report this problem to Google."* ]]; then
                    echo -e "Extract Refresh Failed for $contentName in $full_log_path \n\nContent Name: ${contentName}\nContent Type: ${contentType}\nError Message: ${RED} $errorMessage ${RESET} \n\n${line}" | mail -s "Extract Refresh Failed in Tableau PROD sv2lxtabas07 server" Global-IT-CloudOps@equinix.com,rak@equinix.com
               fi
        else
            echo "No Extract Refresh Failed in $full_log_path"
        fi
    done
done
echo "*******************************************************************************************************"