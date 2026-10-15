#!/bin/bash
#Author : Rajesh Kothuru
current_time=$(date "+%Y.%m.%d")

exec >>/u01/app/scripts/logs/tableauinstallation.txt 2>&1

# Define the file containing the version and download URL
FILE="tableau_installation_details.txt"

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
            # Step 1: Install the Dependencies
            cd /u01/app || exit 1
            sudo yum install -y gdb
            sudo yum install -y chrpath
            sudo yum install -y redhat-lsb-core
            ;;

        2)
            # Step 2: Install the package
            echo "Installing Tableau Server version ${TABLEAU_VERSION}..."
            sudo rpm -ivh --prefix ${TABLEAU_INSTALLER}
            ;;

        3)
            # Step 3: Capture the upgrade command in primary node
            UPGRADE_COMMAND=$(grep -- "--accepteula" /u01/app/scripts/logs/tableauinstallation.txt | head -n 1)
            if [ -n "$UPGRADE_COMMAND" ]; then
               echo "Captured Line: $UPGRADE_COMMAND"
            else
               echo "The line containing '--accepteula' was not found in the output file."
            fi
            ;;

        4)
            # Step 4: Execute the upgrade command
            echo "Upgrading Tableau Server..."
            FINAL_COMMAND="${UPGRADE_COMMAND} -d /u01/app/tableau/tableauserver -f"
            echo "Executing $FINAL_COMMAND"
            ${FINAL_COMMAND}
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
for (( step=start_step; step<=4; step++ )); do
    run_step $step
done

echo "Installed Tableau Server ${TABLEAU_VERSION} successfully on ${current_time}."