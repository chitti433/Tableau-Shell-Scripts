#!/usr/bin/bash

LOG="plugin-server-status.log"

exec >/u01/app/scripts/logs/DR_stop_$current_time.txt 2>&1

echo `date` - "SCRIPT - STARTED"
echo `date` - $1" - SHUTDOWN_STS - STARTED"

# Initialize a variable to track the overall status
OVERALL_STATUS=0

VALIDATE(){
if [ $1 -ne 0 ]; then
echo `date` - "$2 - SHUTDOWN_STS - FAILED" 2>&1 | tee -a $LOG
exit1
else
echo `date` - "$2 - SHUTDOWN_STS - SUCCESS" 2>&1 | tee -a $LOG
fi
}

sudo systemctl stop httpd_excel.service &>>$LOG
VALIDATE $? "httpd_excel service stoped"

sudo systemctl stop tableau-data-extractor.service &>>$LOG
VALIDATE $? "data_extractor service stoped"

sudo service rabbitmq-server stop &>>$LOG
VALIDATE $? "rabbitmq service stoped"

sudo systemctl stop httpd_subscription.service &>>$LOG
VALIDATE $? "httpd_subscription service stoped"

sudo systemctl stop httpd_ppr.service &>>$LOG
VALIDATE $? "httpd_ppr service stoped"

sudo systemctl stop httpd &>>$LOG
VALIDATE $? "httpd service stoped"

sudo systemctl stop tomcat &>>$LOG
VALIDATE $? "appache tomcat stoped"

# Check the overall status and print the final status
if [ $OVERALL_STATUS -eq 1 ]; then
   echo `date` - $1" - SHUTDOWN_STS - FAILED"
else
   echo `date` - $1" - SHUTDOWN_STS - COMPLETED"
fi
echo `date` - "SCRIPT - COMPLETED"