#!/usr/bin/bash

LOG="plugin-server-status.log"
current_time=$(date "+%Y.%m.%d")
R="\e[31m"
G="\e[32m"
N="\e[0m"

exec >/u01/scripts/logs/pluginservicesstop_$current_time.txt 2>&1

echo `date` - $1" - SHUTDOWN_STS - STARTED"

VALIDATE(){
if [ $1 -ne 0 ]; then
echo -e "$2 .. ${R} FAILURE ${N} ${current_time}" 2>&1 | tee -a $LOG
exit1
else
echo -e "$2 .. ${G} SUCCESS ${N} ${current_time}" 2>&1 | tee -a $LOG
fi
}

sudo systemctl stop httpd_excel.service &>>$LOG
VALIDATE $? "httpd_excel service stopped"

sudo systemctl stop tableau-data-extractor.service &>>$LOG
VALIDATE $? "data_extractor service stopped"

sudo service rabbitmq-server stop &>>$LOG
VALIDATE $? "rabbitmq service stopped"

sudo systemctl stop httpd_subscription.service &>>$LOG
VALIDATE $? "httpd_subscription service stopped"

sudo systemctl stop httpd_ppr.service &>>$LOG
VALIDATE $? "httpd_ppr service stopped"

sudo systemctl stop httpd &>>$LOG
VALIDATE $? "httpd service stopped"

sudo systemctl stop tomcat &>>$LOG
VALIDATE $? "appache tomcat stopped"

echo `date` "Stopped Plugin Services"

echo `date` - $1" - SHUTDOWN_STS - COMPLETED"