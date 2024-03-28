<form action='%SELF_URL%' METHOD='POST'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='VENDOR' value='%VENDOR%'>
  <input type='hidden' name='NAS_ID' value='%NAS_ID%'>
  <input type='hidden' name='TYPE' value='%TYPE%'>
  <input type='hidden' name='BRANCH' value='%BRANCH%'>
  <input type='hidden' name='visual' value='$FORM{visual}'>
  <input type='hidden' name='unregister_list' value='$FORM{unregister_list}'>
  <input type='hidden' name='reg_onu' value='$FORM{reg_onu}'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'> _{REGISTRATION}_ ONU</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LINE_PROFILE'>Line-Profile:</label>
        <div class='col-md-8'>
          %LINE_PROFILE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SRV_PROFILE'>Srv-Profile:</label>
        <div class='col-md-8'>
          %SRV_PROFILE_SEL%
        </div>
      </div>

      <div class='form-group row' id='INTERNET_VLAN_SEL_DIV'>
        <label class='col-md-4 col-form-label text-md-right' for='VLAN_ID'>INTERNET VLAN:</label>
        <div class='col-md-8'>
          %INTERNET_VLAN_SEL%
        </div>
      </div>

      <div class='form-group row' id='TR_069_VLAN_SEL_DIV'>
        <label class='col-md-4 col-form-label text-md-right' for='TR_069_VLAN_ID'>TR-069 VLAN:</label>
        <div class='col-md-8'>
          %TR_069_VLAN_SEL%
        </div>
      </div>

      <div class='form-group row' id='IPTV_VLAN_SEL_DIV'>
        <label class='col-md-4 col-form-label text-md-right' for='IPTV_VLAN_ID'>IPTV VLAN:</label>
        <div class='col-md-8'>
          %IPTV_VLAN_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='BRANCH'>Branch:</label>
        <div class='col-md-8'>
          <input id='BRANCH' value='%UC_TYPE% %BRANCH%' readonly class='form-control-plaintext' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MAC_SERIAL'>Mac_Serial:</label>
        <div class='col-md-8'>
          <input id='MAC_SERIAL' name='MAC_SERIAL' value='%MAC_SERIAL%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ONU_DESC'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <input id='ONU_DESC' name='ONU_DESC' value='%ONU_DESC%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DEBUG'>_{DEBUG}_:</label>
        <div class='col-md-8'>
          <select name='DEBUG'>
            <option value=0 selected>--</option>
            <option value=1>1</option>
            <option value=2>2</option>
            <option value=3>3</option>
            <option value=4>4</option>
            <option value=5>5</option>
          </select>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary float-left'>
    </div>
  </div>
  <script type='text/javascript'>
    jQuery(document).ready(function () {

      var inet_vlan_sel_div = jQuery('div#INTERNET_VLAN_SEL_DIV');
      var inet_vlan_select  = jQuery('select#VLAN_ID');
      var tr_069_vlan_sel_div = jQuery('div#TR_069_VLAN_SEL_DIV');
      var tr_069_vlan_select  = jQuery('select#TR_069_VLAN_ID');
      var iptv_vlan_sel_div = jQuery('div#IPTV_VLAN_SEL_DIV');
      var iptv_vlan_select  = jQuery('select#IPTV_VLAN_ID');

      if (jQuery('select#LINE_PROFILE').val() === '%DEF_LINE_PROFILE%') {
        inet_vlan_sel_div.show();
        inet_vlan_select.attr('name', 'VLAN_ID');
        tr_069_vlan_sel_div.hide()
        tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID_HIDE');
        iptv_vlan_sel_div.hide()
        iptv_vlan_select.attr('name', 'IPTV_VLAN_ID_HIDE');
      }
      else if (jQuery('select#LINE_PROFILE').val() === '%TRIPLE_LINE_PROFILE%') {
        inet_vlan_sel_div.show();
        inet_vlan_select.attr('name', 'VLAN_ID');
        tr_069_vlan_sel_div.show();
        tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID');
        iptv_vlan_sel_div.show();
        iptv_vlan_select.attr('name', 'IPTV_VLAN_ID');
      }
      else {
        if ('%SHOW_VLANS%' == 1) {
          inet_vlan_sel_div.show();
        }
        else {
          inet_vlan_sel_div.hide();
        }

        inet_vlan_select.attr('name', 'VLAN_ID_HIDE');
        tr_069_vlan_sel_div.hide()
        tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID_HIDE');
        iptv_vlan_sel_div.hide()
        iptv_vlan_select.attr('name', 'IPTV_VLAN_ID_HIDE');
      }

      jQuery('select#LINE_PROFILE').change(function () {
        if (jQuery('select#LINE_PROFILE').val() === '%DEF_LINE_PROFILE%') {
          inet_vlan_sel_div.show();
          inet_vlan_select.attr('name', 'VLAN_ID');
          tr_069_vlan_sel_div.hide()
          tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID_HIDE');
          iptv_vlan_sel_div.hide()
          iptv_vlan_select.attr('name', 'IPTV_VLAN_ID_HIDE');
        }
        else if (jQuery('select#LINE_PROFILE').val() === '%TRIPLE_LINE_PROFILE%') {
          inet_vlan_sel_div.show();
          inet_vlan_select.attr('name', 'VLAN_ID');
          tr_069_vlan_sel_div.show();
          tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID');
          iptv_vlan_sel_div.show();
          iptv_vlan_select.attr('name', 'IPTV_VLAN_ID');
        }
        else {
          if ('%SHOW_VLANS%' == 1) {
            inet_vlan_sel_div.show();
          }
          else {
            inet_vlan_sel_div.hide();
          }

          inet_vlan_select.attr('name', 'VLAN_ID_HIDE');
          tr_069_vlan_sel_div.hide()
          tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID_HIDE');
          iptv_vlan_sel_div.hide()
          iptv_vlan_select.attr('name', 'IPTV_VLAN_ID_HIDE');
        }
      });
    });
  </script>
</form>
