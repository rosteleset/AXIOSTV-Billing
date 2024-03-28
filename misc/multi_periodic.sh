#!/bin/sh
# Multi periodic script
# Example only

DATETIME=`date "+%Y-%m-%d 00:00:00"`;
INTERVAL_SECONDS=86400
PERIOD_DAYS=30
MODULES="Abon"
DEBUG=0
OS=`uname -s`

periodics_run () {
  DATE=$1

  /usr/axbills/libexec/periodic daily MODULES=${MODULES} DATE="${DATE}" DEBUG=1
  /usr/axbills/libexec/periodic monthly MODULES=${MODULES} DATE="${DATE}" DEBUG=1

}

intervals() {
  UNIX_TIME=`date +"%s"`

  day=0;
  while [ ${day} -lt ${PERIOD_DAYS}  ]; do
    NEXT_DATE=$(expr ${UNIX_TIME} - ${PERIOD_DAYS} \* 86400 + ${INTERVAL_SECONDS} \* ${day});

    if [ "${OS}" = "FreeBSD" ]; then
      DATETIME=`date -r ${NEXT_DATE} "+%Y-%m-%d"`
    else
      DATETIME=`date --date="@${NEXT_DATE}" "+%Y-%m-%d"`
    fi;

    echo "Interval: ${day} / ${DATETIME}";
    periodics_run ${DATETIME};
    day=$( expr ${day} + 1 )
  done;
}


intervals