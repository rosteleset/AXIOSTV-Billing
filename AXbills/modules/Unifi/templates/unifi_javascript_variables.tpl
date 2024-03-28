<script>

  var DEBUG = (parseInt('%DEBUG%') != 0);

  var userURL  = '%USERURLDECODE%' || '';
  var userURL2 = '%USERURL%' || '';

  var mac  = '%USERMAC%' || '';
  var ssid = '%SSID%' || '';
  var ap   = '%APMAC%' || '';
  var ip   = '%USERIP%' || '';

  var cookie_time   = '%COOKIES_TIME%' || '';
  var cookie_path   = '/';
  var cookie_domain = '%HTML_DOMAIN%' || '';
  var cookie_secure = '%HTML_SECURE%' || '';
  var cookieOpts    = {path: cookie_path, domain: cookie_domain, secure: cookie_secure, expires: cookie_time};

  var SELF_URL = '%SELF_URL%';

  if (mac) {
    jQuery.cookie('hotspot_user_id', mac, cookieOpts);
  }

  var lang = {
    "WAIT_FOR_AUTH"  : '_{WAIT_FOR_AUTH}_' || 'Подождите, пока проходит авторизация',
    "UNLIM"          : '_{UNLIM}_' || 'Неограничено',
    "MINUTE"         : '_{MINUTE}_' || 'минута',
    "MINUTES"        : '_{MINUTES}_' || 'минут',
    "DOWNLOAD_SPEED" : '_{DOWNLOAD_SPEED}_' || 'Скорость закачки',
    "UPLOAD_SPEED"   : '_{UPLOAD_SPEED}_' || 'Скорость выгрузки',
    "IP_ADDRESS"     : '_{IP_ADDRESS}_' || 'IP адрес',
    "MAC"            : '_{MAC}_' || 'MAC',
    "SIGNAL"         : '_{SIGNAL}_' || 'Сигнал',
    "TRANSMITTED"    : '_{TRANSMITTED}_' || 'Отправлено',
    "RECEIVED"       : '_{RECEIVED}_' || 'Получено',
    "TIMELEFT"       : '_{TIMELEFT}_' || 'Осталось времени',
    "DISABLE"        : '_{DISABLE}_' || 'Отключить',
    "USER_LINK_LABEL": '_{USER_LINK_LABEL}_' || 'Для перехода на сайт нажмите на ссылку:',
    "MOMENT_LOCALE"  : '_{MOMENT_LOCALE}_' || 'ru',
    "HANGUP"         : '_{HANGUP}_' || 'Отключить'
  }

</script>
