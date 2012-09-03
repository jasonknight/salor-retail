#! /bin/bash
# This script is run from cron once a day in order to generate backups
# of the Salor DB. It's a 30-day rolling backup. #1 is most recent,
# and #30 is from 30 days ago

# Config
backupdir=/opt/salor_db_rolling_backups
database=THEDATABASE
numversions=30
d=$(date)

echo $(date)" - Starting 30-day Salor DB Rolling Backup..."

# Create dir if needed
mkdir -p ${backupdir}/backup.0
if [ ! -d ${backupdir} ]
then
        echo "Invalid directory: ${backupdir}"
exit 1
fi

# Create current backup
cd /var/log
mysqldump --user THEUSER --password=THEPASSWORD --opt ${database} > ${database}.sql
gzip ${database}.sql
mv ${database}.sql.gz ${backupdir}/backup.0/${database}.sql.gz 2> /dev/null

# Rollover the backup directories
i=$numversions
rm -fr ${backupdir}/backup.$i 2> /dev/null
while [ $i -gt 0 ]
do
	mv ${backupdir}/backup.`expr $i - 1` ${backupdir}/backup.$i 2> /dev/null
	i=`expr $i - 1`
done

# Copy the latest backup to the Desktop
cp ${backupdir}/backup.1/${database}.sql.gz /home/salor/Desktop/Salor_Backup.gz 2> /dev/null
cp ${backupdir}/backup.1/${database}.sql.gz /home/zotac/Desktop/Salor_Backup.gz 2> /dev/null
chmod 666 /home/salor/Desktop/Salor_Backup.gz 2> /dev/null
chmod 666 /home/zotac/Desktop/Salor_Backup.gz 2> /dev/null

echo " --> Salor Rolling Backup Complete."
exit 0
