#
# Regular cron jobs for the salor-retail package
#
0 2 * * * root test -x /usr/bin/salor-maintenance && /usr/bin/salor-maintenance r
0 3 * * * root test -x /usr/bin/salor-remote-backup && /usr/bin/salor-remote-backup r
0 4 * * * root test -x /usr/bin/salor-shippers-import && /usr/bin/salor-shippers-import
0 5 * * * root test -x /usr/bin/salor-diagnostics && /usr/bin/salor-diagnostics r

