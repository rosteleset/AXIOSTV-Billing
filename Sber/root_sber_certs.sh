#!/bin/sh
cp /usr/axbills/Sber/russian_trusted_root_ca_pem.crt /usr/local/share/ca-certificates
cp /usr/axbills/Sber/russian_trusted_sub_ca_pem.crt /usr/local/share/ca-certificates

/usr/sbin/update-ca-certificates -v
