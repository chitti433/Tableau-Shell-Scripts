#!/bin/bash

# Variables
INSTALL_DIR=&quot;/u01/app&quot;
DEFAULT_TOMCAT_VERSION=&quot;9.0.24&quot; # Defaulting to currently installed version
TOMCAT_USER=&quot;tabusr&quot; # Adjust if Tomcat runs under a different user
TOMCAT_BASE_URL=&quot;https://downloads.apache.org/tomcat/tomcat-9&quot;

# Fetch the N-1 Tomcat version
N1_TOMCAT_VERSION=$(curl -s $TOMCAT_BASE_URL/ | grep -o &#39;v9\.0\.[0-9]\+&#39; | sed
&#39;s/v//&#39; | sort -V | tail -2 | head -1)

echo &quot;Tomcat version is: $N1_TOMCAT_VERSION&quot;

# Check if we got the correct version
if [ -z &quot;$N1_TOMCAT_VERSION&quot; ]; then
echo &quot;Failed to fetch the N-1 Tomcat version.&quot;
exit 1
fi

# Ask for user confirmation before proceeding
echo &quot;Proceeding to upgrade Tomcat to $N1_TOMCAT_VERSION, please confirm (yes/no):
&quot;
read -r CONFIRM
if [[ &quot;$CONFIRM&quot; != &quot;yes&quot; ]]; then
echo &quot;Upgrade cancelled.&quot;
exit 0
fi

# Check if symlink exists, else use the default hardcoded version
if [ -L &quot;${INSTALL_DIR}/apache-tomcat&quot; ]; then
CURRENT_TOMCAT_DIR=$(readlink -f &quot;${INSTALL_DIR}/apache-tomcat&quot;)
else

CURRENT_TOMCAT_DIR=&quot;${INSTALL_DIR}/apache-tomcat-
${DEFAULT_TOMCAT_VERSION}&quot;
fi

NEW_TOMCAT_DIR=&quot;${INSTALL_DIR}/apache-tomcat-${N1_TOMCAT_VERSION}&quot;
BACKUP_DIR=&quot;${INSTALL_DIR}/backup/apache-tomcat-$(basename
&quot;$CURRENT_TOMCAT_DIR&quot;)-$(date +%F-%H-%M-%S)&quot;
NEW_TOMCAT_ARCHIVE=&quot;${INSTALL_DIR}/apache-tomcat-
${N1_TOMCAT_VERSION}.tar.gz&quot;

# Stop Tomcat using systemctl
echo &quot;Stopping Tomcat...&quot;
sudo systemctl stop tomcat

# Backup current Tomcat installation
if [ -d &quot;$CURRENT_TOMCAT_DIR&quot; ]; then
echo &quot;Backing up current Tomcat to: $BACKUP_DIR&quot;
mkdir -p &quot;$BACKUP_DIR&quot;
cp -r &quot;$CURRENT_TOMCAT_DIR&quot;/* &quot;$BACKUP_DIR/&quot;
fi

# Download latest N-1 Tomcat if not already downloaded
if [ ! -f &quot;$NEW_TOMCAT_ARCHIVE&quot; ]; then
echo &quot;Downloading Apache Tomcat $N1_TOMCAT_VERSION...&quot;
wget -q &quot;${TOMCAT_BASE_URL}/v${N1_TOMCAT_VERSION}/bin/apache-tomcat-
${N1_TOMCAT_VERSION}.tar.gz&quot; -O &quot;$NEW_TOMCAT_ARCHIVE&quot;
fi

# Extract new Tomcat
echo &quot;Extracting Apache Tomcat $N1_TOMCAT_VERSION...&quot;
tar -xzf &quot;$NEW_TOMCAT_ARCHIVE&quot; -C &quot;$INSTALL_DIR&quot;

# Preserve configurations from old Tomcat
if [ -d &quot;$CURRENT_TOMCAT_DIR&quot; ]; then

echo &quot;Copying configurations from old Tomcat $CURRENT_TOMCAT_DIR to
$NEW_TOMCAT_DIR...&quot;
cp -r &quot;$CURRENT_TOMCAT_DIR/conf&quot; &quot;$NEW_TOMCAT_DIR/&quot;
cp -r &quot;$CURRENT_TOMCAT_DIR/logs&quot; &quot;$NEW_TOMCAT_DIR/&quot;
cp -r &quot;$CURRENT_TOMCAT_DIR/webapps&quot; &quot;$NEW_TOMCAT_DIR/&quot;
cp -r &quot;$CURRENT_TOMCAT_DIR/work&quot; &quot;$NEW_TOMCAT_DIR/&quot;
cp -r &quot;$CURRENT_TOMCAT_DIR/temp&quot; &quot;$NEW_TOMCAT_DIR/&quot;
fi

# Update permissions
echo &quot;Setting correct ownership...&quot;
chown -R $TOMCAT_USER:$TOMCAT_USER &quot;$NEW_TOMCAT_DIR&quot;

# Update symbolic link to always point to the latest version
SYMLINK=&quot;${INSTALL_DIR}/apache-tomcat&quot;
if [ -L &quot;$SYMLINK&quot; ]; then
rm -f &quot;$SYMLINK&quot;
fi
ln -s &quot;$NEW_TOMCAT_DIR&quot; &quot;$SYMLINK&quot;

# Update the tomcat.service file to replace the old path with the new symlink
echo &quot;Updating Tomcat systemd service file to use symlink...&quot;
sudo sed -i &quot;s|$CURRENT_TOMCAT_DIR|$SYMLINK|g&quot;
/etc/systemd/system/tomcat.service

# Reload systemd daemon
sudo systemctl daemon-reload

# Start Tomcat using systemctl
echo &quot;Starting Apache Tomcat $N1_TOMCAT_VERSION...&quot;
sudo systemctl start tomcat

# Enable Tomcat to start on boot

sudo systemctl enable tomcat

echo &quot;Upgrade complete! Tomcat is now running version $N1_TOMCAT_VERSION&quot;