#! /bin/bash
# This script is run from cron once a day in order to keep the production
# log from growing too huge. It's a 7-day rolling backup. #1 is most recent,
# and #7 is from 7 days ago

# Config
backupdir=/opt/salor_pos/salor/log
numversions=7
d=$(date)

echo $(date)" - Starting 7-day Salor production.log Rotate..."

# Create current backup
cd ${backupdir}
gzip production.log

# Rollover the backup files
i=$numversions
rm -f ${backupdir}/production.log.$i.gz 2> /dev/null
while [ $i -gt 0 ]
do
	mv ${backupdir}/production.log.`expr $i - 1`.gz ${backupdir}/production.log.$i.gz 2> /dev/null
	i=`expr $i - 1`
done

mv ${backupdir}/production.log.gz ${backupdir}/production.log.1.gz 2> /dev/null
touch ${backupdir}/production.log 2> /dev/null
chmod 777 ${backupdir}/production.log 2> /dev/null

echo " --> Salor production.log Rotate Complete."
exit 0
