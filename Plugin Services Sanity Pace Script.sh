#!/usr/bin/bash
LOG="plugin-server-status.log"
exec >/u01/app/scripts/logs/DR_start_sanity_$current_time.txt 2>&1

echo `date` - "SCRIPT - STARTED"
echo `date` - $1" - SANITY_STS - STARTED"

# Initialize a variable to track the overall status
OVERALL_STATUS=0

VALIDATE(){
if [ $1 -ne 0 ]; then
echo `date` - "$2 - SANITY_STS - FAILED" 2>&1 | tee -a $LOG
else
echo `date` - "$2 - SANITY_STS - SUCCESS" 2>&1 | tee -a $LOG
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

# Check the overall status and print the final status

if [ $OVERALL_STATUS -eq 1 ]; then
   echo `date` - $1" - SANITY_STS - FAILED"
else
   echo `date` - $1" - SANITY_STS - COMPLETED"
fi
echo `date` - "SCRIPT - COMPLETED"