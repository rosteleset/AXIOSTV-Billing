#!/bin/bash
#LOCALDIR=/usr/axbills/misc

names=$0
IP=$1
ssh axbills_admin@192.168.7.243 -i /usr/axbills/Certs/id_rsa.axbills_admin  "/ip firewall nat remove [find comment=$IP]"
#ssh axbills_admin@192.168.7.244 -i /usr/axbills/Certs/id_rsa.axbills_admin  "/ip firewall nat remove [find comment=$IP]"
#ssh axbills_admin@192.168.7.245 -i /usr/axbills/Certs/id_rsa.axbills_admin  "/ip firewall nat remove [find comment=$IP]"
ssh axbills_admin@192.168.7.246 -i /usr/axbills/Certs/id_rsa.axbills_admin  "/ip firewall nat remove [find comment=$IP]"
ssh axbills_admin@192.168.7.247 -i /usr/axbills/Certs/id_rsa.axbills_admin  "/ip firewall nat remove [find comment=$IP]"
ssh axbills_admin@192.168.7.248 -i /usr/axbills/Certs/id_rsa.axbills_admin  "/ip firewall nat remove [find comment=$IP]"
ssh axbills_admin@192.168.7.249 -i /usr/axbills/Certs/id_rsa.axbills_admin  "/ip firewall nat remove [find comment=$IP]"
ssh axbills_admin@192.168.7.250 -i /usr/axbills/Certs/id_rsa.axbills_admin  "/ip firewall nat remove [find comment=$IP]"
