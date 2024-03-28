<form name='PAYSYS_GROUP_SETTINGS' id='form_PAYSYS_GROUP_SETTINGS' method='post'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='SYSTEM_ID' id='SYSTEM_ID' value='%SYSTEM_ID%'>
  <input type='hidden' name='MERCHANT_ID' id='MERCHANT_ID' value='%MERCHANT_ID%'>

  <div class='card big-box card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ADD}_ _{_MERCHANT}_</h4>
    </div>

    <div class='card-body'>
      <div class='form-group %HIDE_SELECT%'>
        <label class=' col-md-12 col-sm-12'>_{PAY_SYSTEM}_</label>
        <div class='col-md-12 col-sm-12'>
          %PAYSYS_SELECT%
        </div>
      </div>

      <div id='paysys_connect_system_body'>
        <div class='form-group' id='ACCOUNT_KEYS_SELECT'>
          <label class=' col-md-12 col-sm-12' id='KEY_NAME'></label>
          <div class='col-md-12 col-sm-12'>
            %ACCOUNT_KEYS_SELECT%
          </div>
        </div>
      </div>

      <div id='paysys_connect_system_body'>
        <div class='form-group' id='PAYMENT_METHOD_SELECT'>
          <label class=' col-md-12 col-sm-12' id='PAYMENT_METHOD_LABEL'></label>
          <div class='col-md-12 col-sm-12'>
            %PAYMENT_METHOD_SELECT%
          </div>
        </div>
      </div>

      <div class='form-group %HIDE_DOMAIN_SEL%'>
        <label class=' col-md-12 col-sm-12'>_{DOMAIN}_</label>
        <div class='col-md-12 col-sm-12'>
          %DOMAIN_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class=' col-sm-12 col-md-12' for='MERCHANT_NAME'>_{MERCHANT_NAME2}_:</label>
        <div class='col-sm-12 col-md-12'>
          <input type='text' class='form-control' id='MERCHANT_NAME' name='MERCHANT_NAME' value='%MERCHANT_NAME%'
                 required>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='%BTN_NAME%' value='%BTN_VALUE%' id='BTN_ADD'>
    </div>
  </div>
</form>

<script>
  try {
    var arr = JSON.parse('%JSON_LIST%');
  } catch (err) {
    console.log('JSON parse error.');
  }

  var KEY_NAME = '';
  var SHOW_SELECT = 0;

  var defaultSelectedValue = jQuery('#MODULE').serialize();
  jQuery('#ACCOUNT_KEYS_SELECT').hide();
  jQuery('#PAYMENT_METHOD_SELECT').hide();

  jQuery('#KEYS')
    .append(new Option('CONTRACT_ID', 'CONTRACT_ID'))
    .append(new Option('UID', 'UID'))
    .append(new Option('LOGIN', 'LOGIN'))
    .append(new Option('EMAIL', 'EMAIL'))
    .append(new Option('PHONE', 'PHONE'))
    .append(new Option('CELL_PHONE', 'CELL_PHONE'))
    .append(new Option('BILL_ID', 'BILL_ID'))
    .append(new Option('_PIN_ABS', '_PIN_ABS'));

  function rebuild_form(type) {
    jQuery('.appended_field').remove();
    let keys = Object.keys(arr[type]['CONF']) || {};
    let sorted = keys.sort();
    let systemID = arr[type]['SYSTEM_ID'] || 0;
    let checkBoxes = arr[type]['CHECKBOX_FIELDS'] || [];
    jQuery('#SYSTEM_ID').attr('value', systemID);

    jQuery('#ACCOUNT_KEYS_SELECT').show();
    jQuery('#PAYMENT_METHOD_SELECT').show();

    for (let i = 0; i < sorted.length; i++) {
      let val = arr[type]['CONF'][sorted[i]];
      let param = sorted[i];
      param = param.replace(/(_NAME_)/, '_' + type.toUpperCase() + '_');

      jQuery("input[name*='MFO']").attr('maxlength', '6')
        .attr('title', 'Поле должно содержать 6 цифр')
        .hover(() => {
          jQuery(this).tooltip()
        });

      if (param.includes('ACCOUNT_KEY')) {
        SHOW_SELECT = 1;
        KEY_NAME = param;
        jQuery('#KEY_NAME').text(param);
        if (val) {
          jQuery('#KEYS').val(val).change();
        } else {
          jQuery('#KEYS').val('UID').change();
        }
      } else if (param.includes('PAYMENT_METHOD')) {
        jQuery('#PAYMENT_METHOD_LABEL').empty();
        jQuery('#PAYMENT_METHOD_LABEL').append(param);
        jQuery('#PAYMENT_METHOD').attr('name', param);
        if (val) {
          jQuery('#PAYMENT_METHOD').val(val).change();
        } else {
          jQuery('#PAYMENT_METHOD').val(' ').change();
        }
      } else if (checkBoxes.includes(param)) {
        const checked = (val === '1') ? 'checked' : '';
        let element = jQuery('<div></div>').addClass('form-group appended_field');
        element.append(jQuery("<label for=''></label>").text(param).addClass('col-md-12 col-sm-12'));
        element.append(jQuery("<div style='display: flex; justify-content: center;'></div>").addClass('col-md-12 col-sm-12').append(
          jQuery(`<input ${checked} style='height: 20px; width:20px' type='checkbox' name='${param || ""}' id='${param || ""}' value='1' data-return='1' data-checked='1'>`)));

        jQuery('#paysys_connect_system_body').append(element);
      } else {
        let element = jQuery('<div></div>').addClass('form-group appended_field');
        element.append(jQuery("<label for='" + (param || '') + "'></label>").text(param).addClass('col-md-12 col-sm-12'));
        element.append(jQuery("<div></div>").addClass('col-md-12 col-sm-12').append(
          jQuery("<input name='" + (param || '') + "' id='" + (param || '') + "' value='" + (val || '') + "'>").addClass('form-control')));

        jQuery('#paysys_connect_system_body').append(element);
      }

      if (i + 1 === sorted.length && SHOW_SELECT === 0) {
        jQuery('#ACCOUNT_KEYS_SELECT').hide();
        jQuery('#PAYMENT_METHOD_SELECT').hide();
      } else if (i + 1 === sorted.length && SHOW_SELECT === 1) {
        SHOW_SELECT = 0;
      }
    }
  }

  jQuery('#BTN_ADD').on('click', () => {
    if (!(jQuery('#' + KEY_NAME).length) && jQuery('#ACCOUNT_KEYS_SELECT:visible').length !== 0) {
      let element = jQuery('<div></div>').addClass('form-group appended_field hidden');
      element.append(jQuery("<label for=''></label>").text(KEY_NAME).addClass('col-md-12 col-sm-12'));
      element.append(jQuery("<div></div>").addClass('col-md-12 col-sm-12').append(
        jQuery("<input name='" + KEY_NAME + "' id='selected_value' value='" + (jQuery('#KEYS').find(':selected').text() || '') + "'>").addClass('form-control')));

      jQuery('#paysys_connect_system_body').append(element);
    } else if (jQuery('#ACCOUNT_KEYS_SELECT:visible').length === 0) {
      jQuery('#selected_value').remove();
    }
  });

  jQuery(() => {
    if (jQuery('#MODULE').val()) {
      rebuild_form(jQuery('#MODULE').val());
    }

    jQuery('#MODULE').on('change', () => {
      rebuild_form(jQuery('#MODULE').val());
    });
  });
</script>
