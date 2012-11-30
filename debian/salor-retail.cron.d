#
# Regular cron jobs for the salor-retail package
#
0 2 * * * root test -x /usr/bin/salor-maintainance && /usr/bin/salor-maintainance r
0 3 * * * root test -x /usr/bin/salor-remote-backup && /usr/bin/salor-remote-backup r
