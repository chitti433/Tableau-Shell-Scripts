#!/bin/bash

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

timeout=1
current_time=$(date "+%Y.%m.%d")
R="\e[31m"
G="\e[32m"
N="\e[0m"
D="************************************"
i="df -h"
tsm_status=$(tsm status)

exec >/u01/app/scripts/logs/michecksanity_$current_time.txt 2>&1

echo -e "---------------------------------------------------------------------------------------------"

#--------Tableau Status--------#
echo -e "Tableau Server Health Check"
#If we need to check the status of all the processes/nodes we need to execute command tsm status -v
tsm status
if [[ $tsm_status == *"RUNNING"* ]]; then
  echo -e "Tableau server Health is ${G}SUCCESS${N} ${current_time}"
else
  echo -e "Tableau Server Health is ${R}FAILURE${N} ${current_time}"
fi

echo -e "---------------------------------------------------------------------------------------------"

#--------Check Mount Storage on all mounted file systems--------#
echo -e "Mount Storage"
echo -e "$D$D"
echo -e "( 0-80% = OK/HEALTHY,  80-95% = WARNING,  95-100% = CRITICAL )"
echo -e "$D$D"

df -h -x tmpfs -x devtmpfs
# Check disk usage of /
usage_root=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

# Check disk usage of /u01
usage_u01=$(df -h /u01 | awk 'NR==2 {print $5}' | cut -d'%' -f1)

# Check disk usage of /boot
usage_boot=$(df -h /boot | awk 'NR==2 {print $5}' | cut -d'%' -f1)

# Check if any of the disk usages exceed the thresholds
if [[ $usage_root -gt 95 ]] || [[ $usage_u01 -gt 95 ]] || [[ $usage_boot -gt 95 ]]; then
    echo -e "Mount Storage ..  ${R} CRITICAL ${N} ${current_time}"
elif [[ $usage_root -gt 80 ]] || [[ $usage_u01 -gt 80 ]] || [[ $usage_boot -gt 80 ]]; then
    echo -e "Mount Storage ..  ${R} WARNING ${N} ${current_time}"
else
    echo -e "Mount Storage ..  ${G} OK/HEALTHY ${N} ${current_time}"
fi


echo -e "---------------------------------------------------------------------------------------------"

#--------Check CPU Memorey Utilization--------#
echo -e "CPU Memorey Usage"
echo -e "$D$D"
echo -e "( 0-80% = OK/HEALTHY,  80-95% = WARNING,  95-100% = CRITICAL )"
echo -e "$D$D"

free -g

mem_usage=$(free -g | awk 'NR==2 {print $3}' | cut -d'%' -f1)

swp_usage=$(free -g | awk 'NR==3 {print $3}' | cut -d'%' -f1)

if [[ $mem_usage -gt 120 ]] || [[ $swp_usage -gt 14 ]]; then
    echo -e "Cpu Memorey Usage ${R} CRITICAL ${N} ${current_time}"
elif [[ $mem_usage -gt 101 ]] || [[ $swp_usage -gt 12 ]]; then
    echo -e "Cpu Memorey Usage ${R} WARNING ${N} ${current_time}"
else
    echo -e "Cpu Memorey Usage ${G} OK/HEALTHY ${N} ${current_time}"
fi

echo -e "---------------------------------------------------------------------------------------------"

#--------Check CPU Utilization--------#
echo -e "CPU Usage"
echo -e "$D$D"
echo -e "( 0-80% = OK/HEALTHY,  80-95% = WARNING,  95-100% = CRITICAL )"
echo -e "$D$D"

# Get the CPU usage percentage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}')

# the CPU usage against different thresholds
if (( cpu_usage > 95 )); then
    echo -e "CPU usage is ${R} CRITICAL${N}: $cpu_usage% ${current_time}"
elif (( cpu_usage >= 85 && cpu_usage <= 95 )); then
    echo -e  "CPU usage is ${R} WARNING${N}: $cpu_usage% ${current_time}"
elif (( cpu_usage > 80 )); then
    echo -e  "CPU usage is ${R} WARNING${N}: $cpu_usage% ${current_time}"
else
    echo -e  "CPU usage is ${G} OK/HEALTHY${N}: $cpu_usage% ${current_time}"
fi

echo -e "---------------------------------------------------------------------------------------------"


#--------Check for Database Conectivity--------#
echo -e "Tableau DB Conncetions Validity"

ping -c 1 -W $timeout DEVSOL &> /dev/null

# Check the exit status of the ping command
if [ $? -ne 0 ]; then
    # Database connectivity is taking longer than expected
    # Generate an alert
    echo -e "EXASOL database is taking longer than ${R}$timeout ${N}seconds to conncting to server${R}not reachable ${N} ${current_time}"
else
    echo -e "EXASOL database is coonecting to server less than ${G}$timeout ${N}second server is ${G}reachable ${N}${current_time}"
fi

ping -c 1 -W $timeout sv2lxbistgdbuat01 &> /dev/null

# Check the exit status of the ping command
if [ $? -ne 0 ]; then
    # Database connectivity is taking longer than expected
    # Generate an alert
    echo -e "ORACLE  database is taking longer than ${R}$timeout ${N}seconds to conncting to server${R} not reachable ${N} ${current_time}"
else
    echo -e "ORACLE database is coonecting to server less than ${G}$timeout ${N}second server is ${G}reachable ${N}${current_time}"
fi

echo -e "---------------------------------------------------------------------------------------------"

#--------Check for LB Server Validation--------#
echo -e "LB Webserver Validation"

ping -c 1 eapuat.equinix.com &> /dev/null
if [ $? -ne 0 ]; then
echo -e "LB Webserver is taking longer than ${R}$timeout ${N}seconds to connecting to server${R} not reachable ${N} ${current_time}"
else
    echo -e "LB Webserver is connecting to server less than ${G}$timeout ${N}second server is ${G}reachable ${N}${current_time}"
fi
echo -e "---------------------------------------------------------------------------------------------"
#--------Check for Network Validation--------#
echo -e "Network Validation"
#If we need to check other servers connectivity insted of sv2lxtabasuat01 we need to enter sv2lxtabasuat02,sv2lxtabasuat03,sv2lxtabasuat04 and sv2lxtabasuat05
ping -c 1 sv2lxtabasuat01 &> /dev/null
if [ $? -ne 0 ]; then
echo -e "Network connectivity is taking longer than ${R}$timeout ${N}seconds to connecting to server${R} not reachable ${N} ${current_time}"
else
    echo -e "Network connectivity is connecting to server less than ${G}$timeout ${N}second server is ${G}reachable ${N}${current_time}"
fi
echo -e "---------------------------------------------------------------------------------------------"


#The command you provided is a shell command that is used to retrieve the disk usage percentage of the root file system ("/").

#Here is a breakdown of the command:

#1. `df -h /`: This command is used to display information about the disk space usage of the root file system ("/"). The "-h" option is used to display the sizes in a human-readable format.

#2. `awk 'NR==2 {print $5}'`: The output of the previous command is piped to the `awk` command. `awk` is a text processing tool that operates on data in columns. In this case, it is used to extract the 5th column (which represents the usage percentage) from the second line (NR==2) of the input.

#3. `cut -d'%' -f1`: The output of the `awk` command is then piped to the `cut` command. `cut` is used to extract specific parts of each line of input. In this case, it is used to remove the "%" symbol from the extracted usage percentage. The "-d'%' -f1" options specify that the delimiter is "%", and only the first field should be extracted.

#4. `usage_root=$(...)`: The entire command is enclosed in parentheses and preceded by "$". This syntax is used to capture the output of the command and assign it to the variable "usage_root". The variable can then be used later in the script or command.

#In summary, the command retrieves the disk usage percentage of the root file system ("/") and assigns it to the variable "usage_root".

# Use the ping command to check database connectivity
# In the `ping` command, the options `-c`, `-W`, are used for specific purposes:

#- `-c 1`: This option specifies the number of ICMP Echo Request packets to send. In this case, `-c 1` means sending only one packet. It is used to send a single ping request to the server and wait for a response.

#- `-W $timeout`: This option sets the timeout value for waiting for a response. The `$timeout` variable is used to specify the timeout value in seconds. If the server does not respond within the specified timeout, the `ping` command will exit.

#- `&> /dev/null`: This part of the command redirects both standard output and standard error to the null device `/dev/null`. It means that the output of the `ping` command will not be displayed on the console. This is done to avoid any unnecessary output and keep the script clean.

#Overall, the `ping` command with these options is used to send a single ping request to the database server and wait for a response within the specified timeout. If the server does not respond within the timeout, it indicates that the database connectivity is taking longer than expected.

#CPU Usage:-

#The command top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' extracts the CPU usage percentage from the output of the top command.

#Let's break down the command step by step:

#top -bn1: This runs the top command in batch mode (-b) for a single iteration (-n1). It outputs the system information and process details.

#grep "Cpu(s)": The grep command filters the output of top and searches for the line that contains "Cpu(s)".

#awk '{print $2 + $4}': The awk command processes the filtered line and extracts the second field ($2), which represents the user CPU usage, and the fourth field ($4), which represents the system CPU usage. It then adds these two values together and prints the result.

#These lines check the CPU usage against different thresholds using conditional statements (if, elif, else, and fi).

#The first if statement checks if the CPU usage is greater than 95. If true, it echoes a critical alert message.
#The elif statement checks if the CPU usage is between 85 and 95 (inclusive). If true, it echoes a high alert message.
#The second elif statement checks if the CPU usage is greater than 80. If true, it echoes a warning message.
#If none of the above conditions are met, the else block is executed, and it echoes a normal message.
#The $cpu_usage variable is used to display the actual CPU usage percentage in the alert messages.

#By running this script, you can check the CPU usage and receive appropriate alerts based on the defined thresholds.