<div class='card card-primary card-outline box-form'>
  <div class='card-body'>

    %MENU%

    <form action='$SELF_URL' method='post' class='form form-horizontal' id='vlan_user_form'>
      <input type=hidden name='index' value='$index'>
      <input type=hidden name='UID' value='$FORM{UID}'>

      <div class='form-group'>
        <label class='control-label col-md-3'>VLAN ID:</label>
        <div class='col-md-9'>
          <input class='form-control' type=text name=VLAN_ID value='%VLAN_ID%' size=8>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>UNNUMBERED IP:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='UNNUMBERED_IP' value='%UNNUMBERED_IP%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{INTERFACE}_ IP:</label>
        <div class='col-md-9'>
          <input class='form-control' type=text name=IP value='%IP%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>Netmask:</label>
        <div class='col-md-9'>
          <input class='form-control' type=text name=NETMASK value='%NETMASK%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>IP _{RANGE}_:</label>
        <div class='col-md-9'>
          %IP_RANGE%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>IP _{COUNT}_:</label>
        <div class='col-md-9'>
          %CLIENT_IPS_COUNT%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{NAS}_:</label>
        <div class='col-md-9'>
          %NAS_LIST%
        </div>
      </div>
      <div class='checkbox'>
        <label>
          <input type='checkbox' name='DHCP' value='1' %DHCP%>
          <strong>DHCP</strong>
        </label>
      </div>
      <div class='checkbox'>
        <label>
          <input type='checkbox' name='PPPOE' value='1' %PPPOE%>
          <strong>PPPoE</strong>
        </label>
      </div>

      <div class='checkbox'>
        <label>
          <input type='checkbox' name='DISABLE' value='1' %DISABLE%>
          <strong>_{DISABLE}_</strong>
        </label>
      </div>

      <div class='checkbox'>
        <label>
          <input type=checkbox name='is_js_confirmed' value='1' class='d-print-none'>
          <strong>_{DEL}_ _{CONFIRM}_</strong>
        </label>
      </div>

    </form>

  </div>
  <div class='card-footer'>
    <input type=submit class='btn btn-danger d-print-none' form='vlan_user_form' name='del' value='_{DEL}_'>
    <input type=submit class='btn btn-success d-print-none' form='vlan_user_form' name='%ACTION%' value='%LNG_ACTION%'>
  </div>
</div>