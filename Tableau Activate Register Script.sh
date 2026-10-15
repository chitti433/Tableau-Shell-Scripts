#!/bin/bash
# Author: Rajesh Kothuru

current_time=$(date "+%Y.%m.%d")

exec >> /u01/app/scripts/logs/tableauactiavteregister.txt 2>&1

# Tableau Product Key
PRODUCT_KEY=TSJ4-9949-06A0-1A03-60AF

echo "[$current_time] Starting Tableau product key activation..."

# Check if tsm is available
if ! command -v tsm &> /dev/null; then
    echo "[$current_time] ERROR: tsm command not found."
    exit 1
fi

# Activate the product key
if tsm licenses activate -k $PRODUCT_KEY; then
    echo "[$current_time] Tableau product key activated successfully."
else
    echo "[$current_time] ERROR: Failed to activate Tableau product key."
    exit 1
fi

# Script to automatically download the Tableau Server registration template
# and fill in the required fields using 'jq', the JSON processor.
#
# NOTE: 'jq' must be installed on your system (e.g., sudo apt install jq)
# --------------------------------------------------------------------------------------

# --- 1. Define Variables ---
# IMPORTANT: Replace these dummy values with the actual data you want to use.
FIRST_NAME="Rajesh"
LAST_NAME="Kothuru"
PHONE="8186899912"
EMAIL="rak@equinix.com"
COMPANY="Equinix"
INDUSTRY="Technology"
COMPANY_EMPLOYEES="1000+"
DEPARTMENT="IT Operations"
TITLE="Cloud Engineer"
CITY="Seattle"
STATE="WA"
ZIP="98101"
COUNTRY="United States"
OPT_IN="false" # Set to "true" or "false"
EULA="accept" # Must be "accept"

JSON_FILE="register.json"

echo "--- Tableau Registration Template Automation ---"

#Check prerequisites ---
if ! command -v jq &> /dev/null; then
    echo "ERROR: 'jq' is not installed. Please install it before running this script."
    exit 1
fi

if ! command -v tsm &> /dev/null; then
    echo "ERROR: 'tsm' command not found. Ensure Tableau Server is installed and 'tsm' is in PATH."
    exit 1
fi

# --- 2. Download the Template (Uncomment for production use) ---
echo "1. Downloading template to $JSON_FILE..."
tsm register --template > $JSON_FILE

# For testing, we simulate the file creation if tsm is not present:
cat << EOF > $JSON_FILE
{
    "first_name" : "Rajesh",
    "last_name" : "Kothuru",
    "phone" : "818689913",
    "email" : "rak@equinix.com",
    "company" : "My Company",
    "industry" : "Finance",
    "company_employees" : "500",
    "department" : "Engineering",
    "title" : "Senior Manager",
    "city" : "Kirkland",
    "state" : "WA",
    "zip" : "98034",
    "country" : "United States",
    "opt_in" : "false",
    "eula" : "accept"
}
EOF
echo "   Template file created/verified."


# --- 3. Fill the Fields using 'jq' ---
# We use multiple --arg flags to safely pass shell variables into the jq filter.
# The filter '.key = $variable' assigns the shell variable to the JSON key.
echo "2. Applying automated field updates to $JSON_FILE..."

# Chain all the updates together using the pipe '|' operator within the jq filter.
# We output to a temporary file and move it back, which is safer for file operations.
jq --arg fn "$FIRST_NAME" \
   --arg ln "$LAST_NAME" \
   --arg ph "$PHONE" \
   --arg em "$EMAIL" \
   --arg co "$COMPANY" \
   --arg ind "$INDUSTRY" \
   --arg emp "$COMPANY_EMPLOYEES" \
   --arg dep "$DEPARTMENT" \
   --arg ti "$TITLE" \
   --arg ci "$CITY" \
   --arg st "$STATE" \
   --arg zi "$ZIP" \
   --arg cnt "$COUNTRY" \
   --arg opt "$OPT_IN" \
   --arg eu "$EULA" \
   '.first_name = $fn |
    .last_name = $ln |
    .phone = $ph |
    .email = $em |
    .company = $co |
    .industry = $ind |
    .company_employees = $emp |
    .department = $dep |
    .title = $ti |
    .city = $ci |
    .state = $st |
    .zip = $zi |
    .country = $cnt |
    .opt_in = $opt |
    .eula = $eu
   ' "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"

if [ $? -eq 0 ]; then
    echo "3. Successfully updated all fields. The new content is:"
    cat $JSON_FILE
else
    echo "ERROR: jq failed to process the JSON file. Please ensure 'jq' is installed."
    exit 1
fi

# --- 4. Submit the registration
echo "4. Submitting registration..."
tsm register --file "$JSON_FILE"

echo "--- Registration completed successfully. ---"

#create the identityStore configuration file and import it
#using the tsm settings import command.
# ----------------------------------------------------------------------

# Updated to use the absolute path for the configuration file
CONFIG_FILE="configuration.json"

echo "--- Tableau Configuration Import Automation ---"

# --- 5. Create the configuration.json file ---
echo "5. Creating configuration file at $CONFIG_FILE with identityStore configuration..."

# Use a 'here document' (cat << EOF) to write the JSON content directly to the file.
cat << EOF > $CONFIG_FILE
{
  "configEntities": {
    "identityStore": {
       "_type": "identityStoreType",
       "type": "local"
     }
   }
}
EOF

if [ $? -eq 0 ]; then
    echo "   $CONFIG_FILE created successfully. Content:"
    # Use 'cat' to display the content from the new absolute path
    cat $CONFIG_FILE
else
    echo "ERROR: Failed to create $CONFIG_FILE. Check directory permissions"
    exit 1
fi

# --- 6. Import the settings using tsm ---
echo "6. Importing settings using 'tsm settings import -f $CONFIG_FILE'..."

# The actual tsm command to apply the configuration
tsm settings import -f $CONFIG_FILE

# For simulation/testing purposes, we'll echo the command:
echo "   [SIMULATING TSM COMMAND] tsm settings import -f $CONFIG_FILE"


#Check the status of the tsm command (if uncommented)
if [ $? -eq 0 ]; then
     echo "7. TSM settings imported successfully."
else
     echo "7. ERROR: TSM settings import failed. Check Tableau logs for details."
     exit 1
fi

# for final Tableau Server configuration and initialization steps.
# This should be run after registration and initial configuration import.
# ----------------------------------------------------------------------

# --- Configuration Variables ---
TIMEOUT=1800 # 1800 seconds = 30 minutes for initialization

echo "--- Tableau Server Final Configuration and Initialization ---"

# --- 8. Set the component samples flag ---
echo "8. Setting configuration key 'install.component.samples' to 'true'..."

# Uncomment the line below to run the actual TSM command:
tsm configuration set -k install.component.samples -v true

# Simulation:
echo "   [SIMULATING TSM COMMAND] tsm configuration set -k install.component.samples -v true"
# Note: tsm configuration set does not typically fail unless tsm is not available.

# --- 8. Apply pending changes (includes identity store and samples setting) ---
echo "8. Applying pending configuration changes. This step can take a moment..."

# Uncomment the line below to run the actual TSM command:
tsm pending-changes apply

# Simulation:
echo "   [SIMULATING TSM COMMAND] tsm pending-changes apply"
# Use the exit code check to ensure the apply was successful before proceeding
if [ $? -ne 0 ]; then
    echo "ERROR: tsm pending-changes apply failed. Initialization cannot proceed."
    exit 1
fi
echo "   Pending changes applied successfully."

# --- 9. Initialize and Start the Server ---
echo "9. Initializing and starting Tableau Server. This is the longest step (up to 30 minutes)..."

# Uncomment the line below to run the actual TSM command:
tsm initialize --start-server --request-timeout $TIMEOUT

# Simulation:
echo "   [SIMULATING TSM COMMAND] tsm initialize --start-server --request-timeout $TIMEOUT"

if [ $? -ne 0 ]; then
    echo "ERROR: tsm initialize failed. Review Tableau Server logs for details on the failure."
    exit 1
fi

echo "Tableau Server initialization complete and server started!"