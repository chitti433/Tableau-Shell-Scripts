# Load the Tableau Server environment variables into the cron environment
source /etc/profile.d/tableau_server.sh
#tsmstatus ='tsm status $tsmparams'
current_time=$(date "+%Y.%m.%d")
exec >/u01/scripts/tsmRestart/logs/ospatchsanity_$current_time.txt 2>&1

echo `date` - $1" - SANITY_STS - STARTED"

if [[ $tsmstatus -eq "RUNNING" ]];
        then
        echo "Server Is RUNNING"
        else
        echo "Server Is DEGRADED"
        fi
echo `date` - $1" - SANITY_STS - COMPLETED"