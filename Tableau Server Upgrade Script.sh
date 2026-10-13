#!/bin/bash
current_time=$(date "+%Y.%m.%d")
WORKER_NODES=("sv2lxtabasint02" "sv2lxtabasint03")

exec >/u01/app/scripts/logs/tableauupgrade.txt 2>&1

# Define the file containing the version and download URL
FILE="tableau_details.txt"

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

# Read the version and download URL from the file
read -r TABLEAU_VERSION < "$FILE"  # Read the first line into TABLEAU_VERSION
read -r TABLEAU_DOWNLOAD_URL < <(sed -n '2p' "$FILE") # Read the second line into TABLEAU_DOWNLOAD_URL
read -r TABLEAU_INSTALLER < <(sed -n '3p' "$FILE") #Read the third line into TABLEAU_INSTALLER
# Output the variables to verify
echo "TABLEAU_VERSION: $TABLEAU_VERSION"
echo "TABLEAU_DOWNLOAD_URL: $TABLEAU_DOWNLOAD_URL"
echo "TABLEAU_INSTALLER: $TABLEAU_INSTALLER"

# Step 1: Download the package
cd /u01/app
echo "Downloading Tableau Server version ${TABLEAU_VERSION}..."
sudo wget ${TABLEAU_DOWNLOAD_URL}

# Check if the download was successful on initial node
if [ $? -ne 0 ]; then
    echo "Failed to download Tableau Server package on initial node ${current_time}"
    exit 1
else
    echo "Tableau server package download success on initial node ${current_time}"
fi

# Step 2: Install the package
echo "Installing Tableau Server version ${TABLEAU_VERSION}..."
sudo rpm -ivh --prefix ${TABLEAU_INSTALLER}

# Check if the installation was successful on initial node
if [ $? -ne 0 ]; then
    echo "Failed to install Tableau package on initial node ${current_time}"
    exit 1
else
    echo "Tableau package install success on initial node ${current_time}"
fi

# Step 3: Download and install the file on each worker node
for WORKER in "${WORKER_NODES[@]}"; do
    echo "Downloading and installing $TABLEAU_VERSION on $WORKER..."

    # Use SSH to execute the wget command on the worker node
    ssh "$WORKER" "cd /u01/app; echo 'Downloading and installing Tableau Server version ${TABLEAU_VERSION}...'; sudo wget ${TABLEAU_DOWNLOAD_URL} && sudo rpm -ivh --prefix ${TABLEAU_INSTALLER}"


# Check if the download and install was successful on worker nodes
if [ $? -ne 0 ]; then
    echo "Failed to download and install Tableau Server on worker nodes ${current_time}"
    exit 1
else
    echo "Tableau server download and installed success on worker nodes ${current_time}"
fi
done

# Step 4: Stop Tableau server
tsm stop

# Check if the stopping of tableau server successful
if [ $? -ne 0 ]; then
    echo "Failed to stop Tableau Server ${current_time}"
    exit 1
else
    echo "Tableau server stopped success ${current_time}"
fi

#Capture the specific line from the output file that contains --accepteula
UPGRADE_COMMAND=$(grep -- "--accepteula" /u01/app/scripts/logs/tableauupgrade.txt | head -n 1)

# Check if the line was found and output it
if [ -n "$UPGRADE_COMMAND" ]; then
    echo "Captured Line: $UPGRADE_COMMAND"
else
    echo "The line containing '--accepteula' was not found in the output file."
fi

# Step 5: Execute the upgrade command
echo "Upgrading Tableau Server..."
${UPGRADE_COMMAND}

# Check if the upgrade command was successful
if [ $? -ne 0 ]; then
    echo "Failed to upgrade Tableau Server ${current_time}"
    exit 1
else
    echo "Tableau server upgrade sucess ${current_time}"
fi

# Step 6: Start Tableau server
tsm start

# Check if the starting of tableau server successful
if [ $? -ne 0 ]; then
    echo "Failed to start Tableau Server ${current_time}"
    exit 1
else
    echo "Tableau server start success ${current_time}"
fi

echo "Tableau Server upgraded to version ${TABLEAU_VERSION} successfully ${current_time}"