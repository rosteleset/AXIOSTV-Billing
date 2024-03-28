<form name='PATHES' id='form_PATHES' method='post' class='form form-horizontal'>
  <input type='hidden' name='index'  value='$index' />
  <input type='hidden' name='action' value='%ACTION%' />

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>%PANEL_HEADING% %FILE_NAME%</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='WEB_SERVER_USER'>_{WEB_SERVER_USER}_: </label>
        <div class='col-md-8'>
          <input class='form-control' id='WEB_SERVER_USER' name='WEB_SERVER_USER' placeholder='www' value=%WEB_SERVER_USER% >
        </div>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='APACHE_CONF_DIR'>Apache _{CONF_DIR}_: </label>
        <div class='col-md-8'>
          <input class='form-control' id='APACHE_CONF_DIR' name='APACHE_CONF_DIR' placeholder='/etc/apache2/sites-enabled/' value=%APACHE_CONF_DIR% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RADIUS_CONF_DIR'>RADIUS _{CONF_DIR}_: </label>
        <div class='col-md-8'>
          <input class='form-control' id='RADIUS_CONF_DIR' name='RADIUS_CONF_DIR' placeholder='/etc/radius/confdir' value=%RADIUS_CONF_DIR% >
        </div>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESTART_MYSQL'>_{RESTART}_ MYSQL: </label>
        <div class='col-md-8'>
          <input class='form-control' id='RESTART_MYSQL' name='RESTART_MYSQL' placeholder='/etc/init.d/mysqld' value=%RESTART_MYSQL% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESTART_RADIUS'>_{RESTART}_ RADIUS: </label>
        <div class='col-md-8'>
          <input class='form-control' id='RESTART_RADIUS' name='RESTART_RADIUS' placeholder='/etc/init.d/freeradius' value=%RESTART_RADIUS% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESTART_APACHE'>_{RESTART}_ Apache: </label>
        <div class='col-md-8'>
          <input class='form-control' id='RESTART_APACHE' name='RESTART_APACHE' placeholder='/etc/init.d/apache2' value=%RESTART_APACHE% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESTART_DHCP'>_{RESTART}_ DHCP: </label>
        <div class='col-md-8'>
          <input class='form-control' id='RESTART_DHCP' name='RESTART_DHCP' placeholder='/etc/init.d/isc-dhcp-server' value=%RESTART_DHCP% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESTART_MPD'>_{RESTART}_ MPD: </label>
        <div class='col-md-8'>
          <input class='form-control' id='RESTART_MPD' name='RESTART_MPD' placeholder='/etc/init.d/mpd' value=%RESTART_MPD% >
        </div>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PING'>PING: </label>
        <div class='col-md-8'>
          <input class='form-control' id='PING' name='PING' placeholder='/bin/ping' value=%PING% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MYSQLDUMP'>MYSQLDUMP: </label>
        <div class='col-md-8'>
          <input class='form-control' id='MYSQLDUMP' name='MYSQLDUMP' placeholder='/usr/bin/mysqldump' value=%MYSQLDUMP% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='GZIP'>GZIP: </label>
        <div class='col-md-8'>
          <input class='form-control' id='GZIP' name='GZIP' placeholder='/bin/gzip' value=%GZIP% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SSH'>SSH: </label>
        <div class='col-md-8'>
          <input class='form-control' id='SSH' name='SSH' placeholder='/usr/bin/ssh' value=%SSH% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SCP'>SCP: </label>
        <div class='col-md-8'>
          <input class='form-control' id='SCP' name='SCP' placeholder='/usr/bin/scp' value=%SCP% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CURL'>CURL: </label>
        <div class='col-md-8'>
          <input class='form-control' id='CURL' name='CURL' placeholder='/usr/bin/curl' value=%CURL% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SUDO'>SUDO: </label>
        <div class='col-md-8'>
          <input class='form-control' id='SUDO' name='SUDO' placeholder='/usr/bin/sudo' value=%SUDO% >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ARP'>ARP: </label>
        <div class='col-md-8'>
          <input class='form-control' id='ARP' name='ARP' placeholder='/usr/sbin/arp' value=%ARP% >
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' form='form_PATHES' class='btn btn-primary' name='button' value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>
