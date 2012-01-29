#! /bin/bash

cat /dev/null > /var/www/salor/log/production-production-history.log
cat /dev/null > /var/www/salor/log/production.log

cat /dev/null > /var/www/salor1/log/production-history.log
cat /dev/null > /var/www/salor1/log/production.log

cat /dev/null > /var/www/salor2/log/production-history.log
cat /dev/null > /var/www/salor2/log/production.log

cat /dev/null > /var/www/salor3/log/production-history.log
cat /dev/null > /var/www/salor3/log/production.log

cd /var/www/salor1
git pull origin master

cd /var/www/salor2
git pull origin master

cd /var/www/salor3
git pull origin master

service apache2 restart
