#!/bin/bash

date1="25.01.2020"
curent=$(date +"%d.%m.%Y" | tr -d ".")
previous=$(echo $date1 | tr -d ".")
result=$(($curent-$previous))

echo $curent
echo $previous
echo $result



date2="25-06-2023"
date3="28-06-2023"
otvet=$(($date3-$date2))

echo $otvet

#kgrhm="$(awk '{system("date +%s --date "$1)}' "$tmpfile" | awk 'NR%2==1{x=$0}NR%2==0{system("date --utc --date=@"$0-x" +%j.%T")}' | awk -F. '{print $1-1" дней, "$2}')"

#echo $kgrhm
logdir=/usr/axbills/misc/accident
ip="100.100.100.100"

tmfile="$logdir"/tmp_"$ip"_0.log
date "+%Y-%m-%dT%H:%M:%S" | tee -a $tmfile

sleep 10

date "+%Y-%m-%dT%H:%M:%S" | tee -a $tmfile

down="$(awk '{system("date +%s --date "$1)}' "$tmfile" | awk 'NR%2==1{x=$0}NR%2==0{system("date --utc --date=@"$0-x" +%j.%T")}' | awk -F. '{print $1-1" day, "$2}')"

echo $down

rm $tmfile
