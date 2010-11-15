# pack SQL tables for backup
# your mysql server has to be on localhost
# you want to run this on a slave database

BASE=/home/xpapers
EVAL="/usr/bin/perl -I$BASE/lib $BASE/bin/eval.pl"

MYSQLDUMP=`$EVAL \\\$MYSQL_BINS`/mysqldump
USER=`$EVAL \\\$DB_SETTINGS{username}`
PASS=`$EVAL \\\$DB_SETTINGS{password}`
DB=`$EVAL \\\$DB_SETTINGS{database}`
GZIP=`$EVAL \\\$GZIP`

FILE=$BASE/back/tables/tables-`date +%A`.sql
CMD="sudo $MYSQLDUMP --user=$USER --password=$PASS --databases $DB --lock-all-tables"
$CMD | gzip > $FILE.gz
#$GZIP $FILE 
