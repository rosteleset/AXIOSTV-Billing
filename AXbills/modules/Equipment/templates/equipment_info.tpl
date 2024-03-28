<script language='JavaScript'>
    function autoReload() {
        document.equipment_info.NAS_ID.value = '$FORM{NAS_ID}';
        document.equipment_info.submit();
    }

    jQuery(function () {
        var base_wiki_link = 'http://axbills.net.ua/wiki/doku.php/axbills:docs:manual:admin:equipment:equipment_info:';
        var model_select = jQuery('select#MODEL_ID');
        var type_select = jQuery('select#TYPE_ID');
        var wiki_link = jQuery('a#MODEL_ID_WIKI_LINK');

        var get_option = function (select, selected) {
            var option = select.find('option[value="' + selected + '"]');
            if (option.length) {
                return option;
            }
            return false
        };

        var update_wiki_link = function (type_name, vendor_name) {
            var formatted_vendor_name = vendor_name.toLowerCase();
            var formatted_type_name = type_name.toLowerCase();
            wiki_link.attr('href', base_wiki_link + formatted_type_name + ':' + formatted_vendor_name);
        };

        var find_vendor_name = function () {
            var option = get_option(model_select, model_select.val());
            if (!option.length) return false;
            return option.data('vendor_name');
        };

        var find_type_name = function () {
            var option = get_option(type_select, type_select.val());
            if (!option.length) return false;
            return option.text();
        };

        var read_form_and_update_link = function () {
            var type_name = find_type_name();
            var vendor_name = find_vendor_name();
            console.log(type_name, vendor_name);
            if (!type_name || !vendor_name) return false;
            update_wiki_link(type_name, vendor_name);
        };

        model_select.on('change', function () {
            read_form_and_update_link();
        });

        read_form_and_update_link();
    });
</script>


<form action='%SELF_URL%' METHOD='post' name='equipment_info'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
  <input type='hidden' name='chg' value='$FORM{chg}'>

  <div class='row d-flex justify-content-center'>

    <div class='col-md-6'>

      <div class='card card-primary card-outline card-form'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{EQUIPMENT}_ _{INFO}_</h4>
        </div>
        <div class='card-body'>

          %EQUIPMENT_IMAGE%

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='NAME'>ID: %NAS_ID%</label>
            <div class='col-md-8'>
              <div class='input-group'>
                <input type='text' class='form-control' placeholder='_{NAME}_: %NAS_NAME% (%NAS_IP%)'
                       name='NAME'
                       readonly value='_{NAME}_: %NAS_NAME% (%NAS_IP%)' ID='NAME'>
                <div class='input-group-append'>
                  <div class='input-group-text'>
                    %NAS_ID_INFO%
                  </div>
                </div>
              </div>
            </div>
          </div>

          %MAP_BTN%

          <div class='form-group row'>
            <label for='TYPE_ID' class='col-md-4 col-form-label text-md-right'>_{TYPE}_:</label>
            <div class='col-md-8'>
              %TYPE_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label for='MODEL_ID' class='col-md-4 col-form-label text-md-right'>_{MODEL}_:</label>
            <div class='col-md-8'>
              %MODEL_SEL% %MANAGE_WEB%
            </div>
          </div>

          <div class='form-group row'>
            <label for='STATUS' class='col-md-4 col-form-label text-md-right'>_{STATUS}_:</label>
            <div class='col-md-8'>
              %STATUS_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label for='LAST_ACTIVITY'
                   class='col-md-4 col-form-label text-md-right'>_{LAST_ACTIVITY}_:</label>
            <div class='col-md-8' style='height: 56px; line-height: 56px; vertical-align: middle;'>
              %LAST_ACTIVITY%
            </div>
          </div>

          <div class='form-group row'>
            <label for='PORTS' class='col-md-4 col-form-label text-md-right'>_{FREE_PORTS}_:</label>
            <div class='col-md-8' style='height: 35px; line-height: 35px; vertical-align: middle;'>
              %FREE_PORTS%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
            <div class='col-md-8'>
              <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
            </div>
          </div>
        </div>

        <div class='card mb-0 card-outline border-top card-big-form collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>SNMP</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>

            <div class='form-group row'>
              <label for='SYSTEM_ID' class='col-md-4 col-form-label text-md-right'>System
                info:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='SYSTEM_ID' placeholder='%SYSTEM_ID%'
                       name='SYSTEM_ID'
                       value='%SYSTEM_ID%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='START_UP_DATE' class='col-md-4 col-form-label text-md-right'>_{VERSION}_
                SNMP:</label>
              <div class='col-md-8'>
                %SNMP_VERSION_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label for='SNMP_TIMEOUT' class='col-md-4 col-form-label text-md-right'>SNMP
                Timeout:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='SNMP_TIMEOUT'
                       placeholder='%SNMP_TIMEOUT%'
                       name='SNMP_TIMEOUT'
                       value='%SNMP_TIMEOUT%'>
              </div>
            </div>

          </div>
        </div>

        <div class='card mb-0 card-outline border-top card-big-form collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{EXTRA}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label for='REVISION'
                     class='col-md-4 col-form-label text-md-right'>_{REVISION}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='REVISION' placeholder='%REVISION%'
                       name='REVISION'
                       value='%REVISION%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='FIRMWARE'
                     class='col-md-4 col-form-label text-md-right'>_{FIRMWARE}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='FIRMWARE' placeholder='%FIRMWARE%'
                       name='FIRMWARE'
                       value='%FIRMWARE%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='SERIAL' class='col-md-4 col-form-label text-md-right'>_{SERIAL}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='SERIAL' placeholder='%SERIAL%'
                       name='SERIAL'
                       value='%SERIAL%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='START_UP_DATE'
                     class='col-md-4 col-form-label text-md-right'>_{START_UP_DATE}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='START_UP_DATE'
                       placeholder='%START_UP_DATE%'
                       name='START_UP_DATE'
                       value='%START_UP_DATE%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='SERVER_VLAN' class='col-md-4 col-form-label text-md-right'>SERVER
                VLAN:</label>
              <div class='col-md-8'>
                %VLAN_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label for='INTERNET_VLAN' class='col-md-4 col-form-label text-md-right'>INTERNET
                VLAN:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='INTERNET_VLAN'
                       placeholder='%INTERNET_VLAN%'
                       name='INTERNET_VLAN'
                       value='%INTERNET_VLAN%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='TR_069_VLAN' class='col-md-4 col-form-label text-md-right'>TR-069
                VLAN:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='TR_069_VLAN' placeholder='%TR_069_VLAN%'
                       name='TR_069_VLAN'
                       value='%TR_069_VLAN%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='IPTV_VLAN' class='col-md-4 col-form-label text-md-right'>IPTV VLAN:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' id='IPTV_VLAN' placeholder='%IPTV_VLAN%'
                       name='IPTV_VLAN'
                       value='%IPTV_VLAN%'>
              </div>
            </div>
          </div>
        </div>

        <div class='card-footer'>
          <input type='submit' name='get_info' value='SNMP _{GET_INFO}_' class='btn btn-default'>
          <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
        </div>
      </div>

    </div>

    %ONU_STATUS%

  </div>

</form>

%EX_INFO%
