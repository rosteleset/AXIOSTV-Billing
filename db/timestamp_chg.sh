find /usr/axbills/db -type f -name '*.sql' -exec sed -i -r "s/CURRENT_TIMESTAMP/'0000-00-00'/g" {} \;
