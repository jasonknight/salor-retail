#! /bin/bash
# This script is run from cron once a day in order to generate backups
# of the Salor DB. GZIPed backups are stored like so:
#   {backupdir}/2011/07/salor_production.sql.gz
# Backups generated with this script are kept FOREVER

# Config
backupdir=/opt/salor_db_backups
database=salor_production

echo $(date)" - Starting Salor DB Daily Backup..."

# Create dir if needed
mkdir -p ${backupdir}/
if [ ! -d ${backupdir} ]
then
	echo "Invalid directory: ${backupdir}"
exit 1
fi

# Dump DB and compress it
cd ${backupdir}
mysqldump --user THEUSER --password=THEPASSWORD --opt ${database} > ${database}.sql
gzip ${database}.sql

# Move file into /BACKUPDIR/YYYY/MM/
mkdir -p ${backupdir}/$(date +%Y)/$(date +%m)/
mv ${database}.sql.gz ${backupdir}/$(date +%Y)/$(date +%m)/salor_db_$(date +%Y%m%d).sql.gz 2> /dev/null

echo " --> Salor Daily Backup Complete."
exit 0
