#!/bin/bash
current_time=$(date "+%Y.%m.%d")
WORKER_NODES=("sv2lxtabas02" "sv2lxtabas03" "sv2lxtabas04" "sv2lxtabas05" "sv2lxtabas06" "sv2lxtabas07")

exec >/u01/app/scripts/logs/tableauupgrade.txt 2>&1

# Define the file containing the version and download URL
FILE="tableau_details.txt"

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

# Read the version and download URL from file
read -r TABLEAU_VERSION < "$FILE"  # Read the first line into TABLEAU_VERSION
read -r TABLEAU_DOWNLOAD_URL < <(sed -n '2p' "$FILE") # Read the second line into TABLEAU_DOWNLOAD_URL
read -r TABLEAU_INSTALLER < <(sed -n '3p' "$FILE") #Read the third line into TABLEAU_INSTALLER

# Output the variables to verify
echo "TABLEAU_VERSION: $TABLEAU_VERSION"
echo "TABLEAU_DOWNLOAD_URL: $TABLEAU_DOWNLOAD_URL"
echo "TABLEAU_INSTALLER: $TABLEAU_INSTALLER"

# Function to run each step
run_step() {
    local step_number=$1
    case $step_number in

        1)
            # Step 1: Check disk usage of /u01
            usage_u01=$(df -h /u01 | awk 'NR==2 {print $5}' | cut -d'%' -f1)
            if [[ $usage_u01 -gt 80 ]]; then
                echo "Mount Storage on sv2lxtabas01 is in Warning State: $usage_u01%"
                exit 1
            else
                echo "Mount Storage on sv2lxtabas01 is Healthy: $usage_u01%"
            fi

            # Checking Mount Space on each worker node
             check_disk_usage() {
                local server=$1
                usage_u01=$(ssh "$server" df -h /u01 | awk 'NR==2 {print $5}' | cut -d'%' -f1)

                if [[ $usage_u01 -gt 80 ]]; then
                    echo "Mount on $server is in Warning State: $usage_u01%"
                    exit 1
                else
                    echo "Mount Storage on $server is Healthy: $usage_u01%"
                fi
            }

            # Loop through each worker node and check disk usage
            for server in "${WORKER_NODES[@]}"; do
                check_disk_usage "$server"
            done
            ;;
        2)
            # Step 2: Download the package
            cd /u01/app || exit 1
            echo "Downloading Tableau Server version ${TABLEAU_VERSION}..."
            sudo wget ${TABLEAU_DOWNLOAD_URL}
            ;;
        3)
            # Step 3: Install the package
            echo "Installing Tableau Server version ${TABLEAU_VERSION}..."
            sudo rpm -ivh --prefix ${TABLEAU_INSTALLER}
            ;;
        4)
            # Step 4: Download and install the file on each worker node
            for WORKER in "${WORKER_NODES[@]}"; do
                echo "Installing $TABLEAU_VERSION on $WORKER..."
                ssh "$WORKER" "cd /u01/app; echo 'Downloading and installing Tableau Server version ${TABLEAU_VERSION}...'; sudo wget ${TABLEAU_DOWNLOAD_URL} && sudo rpm -ivh --prefix ${TABLEAU_INSTALLER}"
            done
            ;;
        5)
            # Step 5: Stop Tableau server
            tsm stop
            ;;
        6)
            # Step 6: Capture the upgrade command in primary node
            UPGRADE_COMMAND=$(grep -- "--accepteula" /u01/app/scripts/logs/tableauupgrade.txt | head -n 1)
            if [ -n "$UPGRADE_COMMAND" ]; then
               echo "Captured Line: $UPGRADE_COMMAND"
            else
               echo "The line containing '--accepteula' was not found in the output file."
            fi
            ;;

        7)
            # Step 7: Execute the upgrade command
            echo "Upgrading Tableau Server..."
            ${UPGRADE_COMMAND}
            ;;
        8)
            # Step 8: Start Tableau server
            tsm start
            ;;

        *)
            echo "Invalid step number"
            return 1
            ;;
    esac

    # Check if the last command was successful
    if [ $? -ne 0 ]; then
        echo "Step $step_number failed. Exiting."
        exit 1
    else
        echo "Step $step_number completed successfully."
    fi
}

# Main script logic
start_step=1  # Default to start from step 1

# Check if a specific step was provided as an
if [ $# -eq 1 ]; then
    start_step=$1
fi

# Loop through the steps
for (( step=start_step; step<=8; step++ )); do
    run_step $step
done

echo "Tableau Server upgraded to version ${TABLEAU_VERSION} successfully on ${current_time}."