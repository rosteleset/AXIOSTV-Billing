## Автоматическая Система Расчётов AXIOSTV.
## Описание billd плагинов

## clear_db - Занимается очисткой базы
## Запуск
```
/usr/axbills/libexec/billd clear_db CLEAR_MAX=ALL - запускаются все чистки
/usr/axbills/libexec/billd clear_db - запускается чистка нулевого уида
```

## stalker_online - логирование данных stalker portal
## Запуск
```
/usr/axbills/libexec/billd stalker_online - не логирует периодик
/usr/axbills/libexec/billd stalker_online LOG_PRINT=1 - логирует в общий лог и выводит в виджете Интернет Ошибка
/usr/axbills/libexec/billd stalker_online LOG_PRINT=1 LOG_FILE=1 логирует в папку по умолчанию /usr/abils/var/log/stalker_online.log
