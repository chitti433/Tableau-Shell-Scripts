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
#read -r TABLEAU_DOWNLOAD_URL < <(sed -n '2p' "$FILE") # Read the second line into TABLEAU_DOWNLOAD_URL
read -r TABLEAU_INSTALLER < <(sed -n '3p' "$FILE") #Read the third line into TABLEAU_INSTALLER

# Output the variables to verify
echo "TABLEAU_VERSION: $TABLEAU_VERSION"
#echo "TABLEAU_DOWNLOAD_URL: $TABLEAU_DOWNLOAD_URL"
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
            # --- Configuration Variables ---
            # IMPORTANT: Update this variable with the correct, full versioned path
            SCRIPTS_DIR="/u01/app/tableau/packages/scripts.20251.25.0520.1026"
            BOOTSTRAP_FILE="/u01/app/bootstrap.json"
            INSTALL_DIR="/u01/app/tableau/tableauserver/"

            echo "--- Tableau Worker Node Installation Automation ---"

            # --- 1. Pre-Check: Verify Bootstrap File ---
            echo "i). Checking for bootstrap file at $BOOTSTRAP_FILE..."
            if [ ! -f "$BOOTSTRAP_FILE" ]; then
            echo "ERROR: Bootstrap file not found! Please copy the bootstrap.json file from the initial node to $BOOTSTRAP_FILE."
            exit 1
            fi
            echo "   Bootstrap file found."

            # --- 2. Change Directory to Execute Script (Crucial for relative paths) ---
            # We change directory into the scripts folder because initialize-tsm often relies
            # on internal relative path references.
            echo "ii). Changing directory to $SCRIPTS_DIR..."
            cd "$SCRIPTS_DIR"
            if [ $? -ne 0 ]; then
            echo "ERROR: Failed to change directory to $SCRIPTS_DIR. Check path and permissions."
            exit 1
            fi

            # --- 3. Execute initialize-tsm with sudo ---
            echo "iii). Executing initialize-tsm to join the cluster..."
            #NOTE: This requires the 'tdev' user to be configured in 'sudoers' for NOPASSWD access."

            # The full command to initialize the worker node:
            # We use the explicit path for the script: ./initialize-tsm
            INSTALL_COMMAND="./initialize-tsm -b $BOOTSTRAP_FILE --accepteula -d $INSTALL_DIR -f"

            echo "   Running: sudo $INSTALL_COMMAND"

            # Uncomment the line below to run the actual command:
            sudo $INSTALL_COMMAND

            # Simulation:
            echo "   [SIMULATING INSTALLATION] Please wait (simulated 5 seconds)..."
            sleep 5

            # Check the exit status of the sudo command
            if [ $? -eq 0 ]; then
            echo "--- Worker Node installation successfully completed and joined the cluster! ---"
            else
            echo "FATAL ERROR: The initialize-tsm command failed."
            echo "Possible reasons: Sudo password prompt (check sudoers), missing bootstrap file, or corrupted installation."
            exit 1
            fi
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
for (( step=start_step; step<=3; step++ )); do
    run_step $step
done