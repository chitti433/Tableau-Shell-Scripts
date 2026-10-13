#!/usr/bin/bash

LOG="plugin-server-status.log"
current_time=$(date "+%Y.%m.%d")
R="\e[31m"
G="\e[32m"
N="\e[0m"

exec >/u01/scripts/logs/pluginservicesstart_$current_time.txt 2>&1

echo `date` - $1" - STARTUP_STS - STARTED"

VALIDATE(){
if [ $1 -ne 0 ]; then
echo -e "$2 .. ${R} FAILURE ${N} ${current_time}" 2>&1 | tee -a $LOG
exit1
else
echo -e "$2 .. ${G} SUCCESS ${N} ${current_time}" 2>&1 | tee -a $LOG
fi
}

sudo systemctl start httpd_excel.service &>>$LOG
VALIDATE $? "httpd_excel service started"

sudo systemctl start tableau-data-extractor.service &>>$LOG
VALIDATE $? "data_extractor service started"

sudo service rabbitmq-server start &>>$LOG
VALIDATE $? "rabbitmq service started"

sudo systemctl start httpd_subscription.service &>>$LOG
VALIDATE $? "httpd_subscription service started"

sudo systemctl start httpd_ppr.service &>>$LOG
VALIDATE $? "httpd_ppr service started"

sudo systemctl start httpd &>>$LOG
VALIDATE $? "httpd service started"

sudo systemctl start tomcat &>>$LOG
VALIDATE $? "appache tomcat started"

sudo su - obiee
nohup sh ~/anaconda3/lib/python3.7/site-packages/tabpy_server/startup.sh 9001 &
VALIDATE $? "tabpy service started"

echo `date` "Started Plugin Services"

echo `date` - $1" - STARTUP_STS - COMPLETED"