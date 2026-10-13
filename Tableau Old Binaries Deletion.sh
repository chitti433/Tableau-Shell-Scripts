#!/bin/bash
current_time=$(date "+%Y.%m.%d")
WORKER_NODES=("sv2lxtabasdev03" "sv2lxtabasdev04")

# Get the current version using the tsm version command
version_output=$(tsm version)
echo "$version_output"

# Extract the version number (e.g., 0335) from the output
current_version=$(echo "$version_output" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -n 1)
echo "Current version: $current_version"

# Check if current_version is empty
if [ -z "$current_version" ]; then
    echo "Error: Current version could not determined"
    exit 1
fi

# List installed Tableau Server packages
installed_packages=$(sudo yum list tableau-server"*")

# Debugging output for installed packages
echo "$installed_packages"

# Loop through installed binaries and remove old versions
old_binaries_found=false
echo "$installed_packages" | grep tableau-server | while read -r line; do
    package_name=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | grep -oP '\d+\.\d+\.\d+\.\d+')

# Trim any whitespace (if any)
    version=$(echo "$version" | xargs)
    current_version=$(echo "$current_version" | xargs)
echo "Comparing installed version: '$version' (length: ${#version}) with current version: '$current_version' (length: ${#current_version})"
# Only remove the package if its version is not the current version
    if [[ "$version" != "$current_version" ]]; then
        echo "Removing old binary: $package_name"
        sudo yum remove -y "$package_name"
        old_binaries_found=true
    else
        echo "Current binary (not removing): $package_name"
    fi
done

if [ "$old_binaries_found" != false ]; then
    echo "There are no old binaries to remove."
fi

remove_old_binaries () {
       local server=$1
       # Get the current version using the tsm version command
version_output=$(tsm version)
echo "$version_output"

# Extract the version number (e.g., 0335) from the output
current_version=$(echo "$version_output" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -n 1)
echo "Current version: $current_version"

# Check if current_version is empty
if [ -z "$current_version" ]; then
    echo "Error: Current version could not determined"
    exit 1
fi

# List installed Tableau Server packages
installed_packages=$(ssh $"server" sudo yum list tableau-server"*")

# Debugging output for installed packages
echo "$installed_packages"

# Loop through installed binaries and remove old versions
old_binaries_found=false
echo "$installed_packages" | grep tableau-server | while read -r line; do
    package_name=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | grep -oP '\d+\.\d+\.\d+\.\d+')

# Trim any whitespace (if any)
    version=$(echo "$version" | xargs)
    current_version=$(echo "$current_version" | xargs)
echo "Comparing installed version: '$version' (length: ${#version}) with current version: '$current_version' (length: ${#current_version})"
# Only remove the package if its version is not the current version
    if [[ "$version" != "$current_version" ]]; then
        echo "Removing old binary: $package_name"
        ssh "$server" sudo yum remove -y "$package_name"
        old_binaries_found=true
    else
        echo "Current binary (not removing): $package_name"
    fi
done

if [ "$old_binaries_found" != false ]; then
    echo "There are no old binaries to remove."
fi
}

# Loop through each worker node to remove old binaries
            for server in "${WORKER_NODES[@]}"; do
                remove_old_binaries "$server"
            done