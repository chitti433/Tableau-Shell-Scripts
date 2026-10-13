#!/usr/bin/bash

LOG="plugin-server-status.log"
current_time=$(date "+%Y.%m.%d")
R="\e[31m"
G="\e[32m"
N="\e[0m"

exec >/u01/scripts/logs/pluginservicessanity_$current_time.txt 2>&1

echo `date` - $1" - SANITY_STS - STARTED"

VALIDATE(){	
if [ $1 -ne 0 ]; then
echo -e "$2 .. ${R} FAILURE ${N} ${current_time}" 2>&1 | tee -a $LOG
exit1
else
echo -e "$2 .. ${G} SUCESS ${N} ${current_time}" 2>&1 | tee -a $LOG
fi
}

sudo systemctl status httpd_excel.service &>>$LOG
VALIDATE $? "httpd_excel service Running"

sudo systemctl status tableau-data-extractor.service &>>$LOG
VALIDATE $? "data_extractor service Running"

sudo service rabbitmq-server status &>>$LOG
VALIDATE $? "rabbitmq service running"

sudo systemctl status httpd_subscription.service &>>$LOG
VALIDATE $? "httpd_subscription service Running"

sudo systemctl status httpd_ppr.service &>>$LOG
VALIDATE $? "httpd_ppr service Running"

sudo systemctl status httpd &>>$LOG
VALIDATE $? "httpd service Running"

sudo systemctl status tomcat &>>$LOG
VALIDATE $? "tomcat service Running"

echo `date` - pluginservices" - SANITY_STS - COMPLETED"

#why we used 2>&1 because in conosle what we are geeting sucess or failure we need to see that in log file that's why we using and -a is for append and we use tee command because always tee command will take only sucess output