#!/usr/bin/bash

LOG="plugin-server-status.log"

exec >/u01/app/scripts/logs/DR_start_$current_time.txt 2>&1

echo `date` - "SCRIPT - STARTED"
echo `date` - $1" - STARTUP_STS - STARTED"

# Initialize a variable to track the overall status
OVERALL_STATUS=0

VALIDATE(){
if [ $1 -ne 0 ]; then
echo `date` - "$2 - STARTUP_STS - FAILED" 2>&1 | tee -a $LOG
exit1
else
echo `date` - "$2 - STARTUP_STS - SUCCESS" 2>&1 | tee -a $LOG
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

# Check the overall status and print the final status

if [ $OVERALL_STATUS -eq 1 ]; then
   echo `date` - $1" - STARTUP_STS - FAILED"
else
   echo `date` - $1" - STARTUP_STS - COMPLETED"
fi
echo `date` - "SCRIPT - COMPLETED"