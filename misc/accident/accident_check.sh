#!/bin/bash
file="ip_list"
#IFS=$'\n'
logdir=/usr/axbills/var/log/accident

config_file="/usr/axbills/libexec/config.pl"

dbname="$(grep 'dbname'  $config_file | cut -d "'" -f2)"
dbuser="$(grep 'dbuser'  $config_file | cut -d "'" -f2)"
dbpasswd="$(grep 'dbpasswd'  $config_file | cut -d "'" -f2)"
dbhost="$(grep 'dbhost'  $config_file | cut -d "'" -f2)"

bot="$(grep 'ACCIDENT_TELEGRAM_BOT'  $config_file | cut -d "'" -f2)"
chat="$(grep 'ACCIDENT_TELEGRAM_CHAT_ID'  $config_file | cut -d "'" -f2)"
list="$(grep 'ACCIDENT_MONITOR_IP'  $config_file | cut -d "'" -f2)"

/usr/bin/rm "$logdir"/anna

#echo $1

if [[ "$1" = GET_FROM_DB ]]; then
#    echo "OK"
    echo "SELECT name, INET_NTOA(ip) FROM nas" | mysql -u "$dbuser" -p"$dbpasswd" "$dbname" >"$logdir"/anna
    sed -i '1d' "$logdir"/anna
#    cat "$logdir"/anna
elif [[ "$1" =  GET_FROM_CONFIG ]]; then
#    echo "Not OK"
#    echo $list
    echo $list > "$logdir"/anna.tmp
      cat "$logdir"/anna.tmp | while IFS=$',' read aa ab ac ad ae af ag ah ai aj ak al am an ao ap aq ar as at au av aw ax ay az
        do
          echo "NAS_Server $aa" >> "$logdir"/anna
          echo "NAS_Server $ab" >> "$logdir"/anna
          echo "NAS_Server $ac" >> "$logdir"/anna
          echo "NAS_Server $ad" >> "$logdir"/anna
          echo "NAS_Server $ae" >> "$logdir"/anna
          echo "NAS_Server $af" >> "$logdir"/anna
          echo "NAS_Server $ag" >> "$logdir"/anna
          echo "NAS_Server $ah" >> "$logdir"/anna
          echo "NAS_Server $ai" >> "$logdir"/anna
          echo "NAS_Server $aj" >> "$logdir"/anna
          echo "NAS_Server $ak" >> "$logdir"/anna
          echo "NAS_Server $al" >> "$logdir"/anna
          echo "NAS_Server $am" >> "$logdir"/anna
          echo "NAS_Server $an" >> "$logdir"/anna
          echo "NAS_Server $ao" >> "$logdir"/anna
          echo "NAS_Server $ap" >> "$logdir"/anna
          echo "NAS_Server $aq" >> "$logdir"/anna
          echo "NAS_Server $ar" >> "$logdir"/anna
          echo "NAS_Server $as" >> "$logdir"/anna
          echo "NAS_Server $at" >> "$logdir"/anna
          echo "NAS_Server $au" >> "$logdir"/anna
          echo "NAS_Server $av" >> "$logdir"/anna
          echo "NAS_Server $aw" >> "$logdir"/anna
          echo "NAS_Server $ax" >> "$logdir"/anna
          echo "NAS_Server $ay" >> "$logdir"/anna
          echo "NAS_Server $az" >> "$logdir"/anna
#          cat "$logdir"/anna
        done
else
echo "Missing parametr"
echo "use GET_FROM_CONFIG"
echo "or"
echo "GET_FROM_DB"
fi

#echo "SELECT name, INET_NTOA(ip) FROM nas" | mysql -u "$dbuser" -p"$dbpasswd" "$dbname" >"$logdir"/anna

#sed -i '1d' "$logdir"/anna

cat "$logdir"/anna | while read name ip; do

# echo "Запуск $name";
# echo "IP $ip"

FILE="$logdir"/host_"$ip"_status.log
# echo $FILE;

if test -f "$FILE"; then
    echo "Файл со статусом есть" >/dev/null
else
    echo "connected" > "$logdir"/host_"$ip"_status.log
fi

status="$(cat "$logdir"/host_"$ip"_status.log)"
logfile="$logdir"/ping_"$ip"_host.log
tmfile="$logdir"/tmp_"$ip"_0.log
#echo $tmpfile
chkfile="$logdir"/chk_"$ip".log
        result=$(ping -c 2 $ip 2<&1| grep -icE 'unknown|expired|unreachable|time out|100% packet loss')
                if [[ "$result" != 0 && "$status" = connected ]]; then
                        datim=$(date '+%Y.%m.%d %H:%M:%S');
                        date "+%Y.%m.%d %H:%M:%S Связи не было" | tee -a "${logfile}"
                        date "+%Y-%m-%dT%H:%M:%S" | tee -a $tmfile
                        echo 'disconnected' > "$logdir"/host_"$ip"_status.log
			curl -s -X POST https://api.telegram.org/bot"$bot"/sendMessage -d chat_id="$chat" -d text="📡 WARNING! $datim 🖥 $name ($ip) - ERROR !"
                elif [[ "$result" = 0 && "$status" = disconnected ]]; then
                        datim=$(date '+%Y.%m.%d %H:%M:%S');
                        date "+%Y.%m.%d %H:%M:%S Связь появилась" | tee -a "${logfile}"
                        date "+%Y-%m-%dT%H:%M:%S" | tee -a $tmfile
                        echo 'connected' > "$logdir"/host_"$ip"_status.log
                        down="$(awk '{system("date +%s --date "$1)}' "$tmfile" | awk 'NR%2==1{x=$0}NR%2==0{system("date --utc --date=@"$0-x" +%j.%T")}' | awk -F. '{print $1-1" day "$2}')"
                        curl -s -X POST https://api.telegram.org/bot"$bot"/sendMessage -d chat_id="$chat" -d text="📡WARNING! $datim 🖥 $name ($ip) - GOOD! it was down $down"
                        /usr/bin/rm $tmfile
                else
echo "Сейчас $name $ip" >/dev/null
fi

done

/usr/bin/rm "$logdir"/anna
/usr/bin/rm "$logdir"/anna.tmp
