#!/bin/bash

# Set the timeout value in seconds
timeout=1
current_time=$(date "+%Y.%m.%d")
G="\e[32m"
R="\e[31m"
N="\e[0m"

ping -c 1 -W $timeout UATSOL &> /dev/null

# Check the exit status of the ping command
if [ $? -ne 0 ]; then
    # Database connectivity is taking longer than expected
    # Generate an alert
    echo -e "EXASOL database is taking longer than ${R}$timeout ${N}seconds to conncting to server${R}not reachable ${N} ${current_time}" | mail -s "EXASOL DB Is Not Reachable" rak@equinix.com
else
    echo -e "EXASOL database is coonecting to server less than ${G}$timeout ${N}second server is ${G}rehable ${N}${current_time}"
fi

#!/bin/bash

# Set the timeout value in seconds
timeout=1
current_time=$(date "+%Y.%m.%d")
G="\e[32m"
R="\e[31m"
N="\e[0m"

ping -c 1 -W $timeout sv2lxbistgdbuat301 &> /dev/null

# Check the exit status of the ping command
if [ $? -ne 0 ]; then
    # Database connectivity is taking longer than expected
    # Generate an alert
    echo -e "ORACLE  database is taking longer than ${R}$timeout ${N}seconds to conncting to server${R} not reachable ${N} ${current_time}" | mail -s "ORACLE DB Is Not Reachable" rak@equinix.com
else
    echo -e "ORACLE database is coonecting to server less than ${G}$timeout ${N}second server is ${G}rehable ${N}${current_time}"
fi