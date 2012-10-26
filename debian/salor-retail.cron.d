#
# Regular cron jobs for the salor-hospitality package
#
0 4	* * *	root	[ -x /usr/bin/salor-maintainance ] && /usr/bin/salor-maintainance r