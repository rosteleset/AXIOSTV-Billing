<script type='text/JavaScript'>
  <!--
  function Process(version, INTERNAL_SUBNET, wds, SSID) {
    var commandbegin = '%PARAM1%';
    var commandend   = '%PARAM2%';

    var commandversion = '';
    var commandsubnet  = '';
    var commandwds     = '';
    var commandsid     = '';

    if (version == 'v24') {
      commandversion = '&version=v24';
    }
    else if (version == 'coova') {
      commandversion = '&version=coova';
    }
    else if (version == 'freebsd') {
      commandversion = '&version=freebsd';
      commandbegin   = commandbegin.replace('wget -O', '/usr/bin/fetch -o')
    }

    if (document.FORM_NAS.LAN_IP && document.FORM_NAS.LAN_IP.value != '') {
      commandsubnet = '&LAN_IP=' + document.FORM_NAS.LAN_IP.value;
    }
    else {
      if (INTERNAL_SUBNET != '20') {
        commandsubnet = '&INTERNAL_SUBNET=' + INTERNAL_SUBNET;
      }
    }

    if (wds != '0') {
      commandwds = '&wds=' + wds;
    }

    if (SSID != '') {
      commandsid = '&SSID=' + SSID;
    }

    document.FORM_NAS.tbox.value = commandbegin + commandversion + commandsid + commandsubnet + commandwds + '"' + commandend;
  }
  //-->
</script>

<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'>
    Hotspot _{SETTINGS}_
  </div>
  <div class='card-body'>
    <input type=hidden name=wds id=wds class='form-control' value='0'/>

    <div class='form-group'>
      <div class='col-xs-3'>
        <label for='version'>Firmware Version:</label>
      </div>
      <div class='col-xs-9'>
        <select name='version' class='form-control' id='version'
                onchange='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)'>
          <option value='v24'>DD-WRT v24 NoKaid/Standard/Mega/Special</option>
          <option value='v23'>DD-WRT v23 Standard</option>
          <option value='coova'>CoovaAP</option>
          <option value='freebsd'>FreeBSD</option>
        </select>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-md-3' for='INTERNAL_SUBNET'> SSID:</label>
      <div class='col-xs-9'>
        <input name='CUSTOM_SID' class='form-control' type='text' id='CUSTOM_SID' value='wifi' size='18' maxlength='14'
               oninput='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-5' for='INTERNAL_SUBNET'> Set router's internal IP to:</label>
      <div class='col-xs-2'><p class='form-control-static'>192.168.</p></div>
      <div class='col-xs-2'>
        <input name='INTERNAL_SUBNET' class='form-control' type='text' id='INTERNAL_SUBNET' value='20' size='3'
               maxlength='3'
               oninput='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)'/>
      </div>
      <div class='col-xs-1'>
        <p class='form-control-static'>.1</p>
      </div>
      <div class='col-xs-2'></div>
    </div>

    <!--
    <br>
    Custom Network: <input name=\"LAN_IP\" class=\"form-control\" type=\"text\"  id=\"LAN_IP\" value=\"\" size=\"16\" maxlength=\"16\"
                  onchange=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\"
                  onsubmit=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\"
                  onKeyPress='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value); return disableEnterKey(event)' />
    -->



    <div class='form-group'>
      <div class='col-xs-1'></div>
      <div class='col-xs-10'>
        <textarea class='form-control' name=tbox rows=4 id=tbox cols=50>%CONFIGURE_DATE%</textarea>
      </div>
      <div class='col-xs-1'></div>
    </div>
  </div>
  <div class='form-group'>
    <a href='_{SELF_URL}_?index=$index&wrt_configure=1&nas=$FORM{NAS_ID}' class='btn btn-xs btn-secondary'>_{CONFIG}_</a>
  </div>
</div>
