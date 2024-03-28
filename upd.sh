#!/bin/bash

UPDFILE=/var/log/billing/update.log
DBFILE=/var/log/billing/check_db.log
message="$(date +"%y-%m-%d %T")"

echo "====================================================">>$UPDFILE
echo $message " - Обновление запущено" >>$UPDFILE
echo "====================================================">>$UPDFILE
(cd /usr/axbills && /usr/bin/git stash >>$UPDFILE 2>&1)
(cd /usr/axbills && /usr/bin/git stash drop >>$UPDFILE 2>&1)
(cd /usr/axbills && /usr/bin/git pull >>$UPDFILE 2>&1)
echo "====================================================">>$UPDFILE
echo $message " - Обновление закончилось" >>$UPDFILE
echo "====================================================">>$DBFILE
echo $message " - начали проверку базы данных">>$DBFILE
echo "====================================================">>$DBFILE
(cd /usr/axbills/misc && /usr/axbills/misc/db_check/db_check.pl CREATE_NOT_EXIST_TABLES APPLY_ALL=1 >>$DBFILE 2>&1)
echo "====================================================">>$DBFILE
echo $message " - проверка базы данных завершена">>$DBFILE


