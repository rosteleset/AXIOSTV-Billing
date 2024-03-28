<form name='PAYSYS_CONNECT_SYSTEM' id='FORM_PAYSYS_CONNECT_SYSTEM' method='post'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='OLD_NAME' value='%NAME%'>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ADD}_ _{PAY_SYSTEM}_</h4>
    </div>
    <div class='card-body'>
      <div id='PAY_SYSTEM_CONTAINER' class='form-group row %HIDE_SELECT%'>
        <label class='col-md-4 col-form-label text-md-right'>_{PAY_SYSTEM}_:</label>
        <div class='col-md-8'>
          %PAYSYS_SELECT%
        </div>
      </div>

        <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='paysys_id'>ID:</label>
        <div class='col-md-8'>
          <input type='number' class='form-control' name='PAYSYS_ID' value='%PAYSYS_ID%' id='paysys_id' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' FOR='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='PRIORITY' id='PRIORITY' value='%PRIORITY%' >
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='paysys_name'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' required placeholder='%NAME%' class='form-control'
                 type='text' %GID_DISABLE% data-check-for-pattern='^[A-Za-z0-9_]{1,30}\$'
                 data-check-for-pattern-text='_{PAYSYS_SYSTEM_ALLOWED_CHARS}_'>
        </div>
      </div>

      <div id='SUBSYSTEM_CONTAINER' hidden class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SUBSYSTEM_ID'>_{SUBSYSTEM}_</label>
        <div class='col-md-8'>
          <select id='SUBSYSTEM_ID' name='SUBSYSTEM_ID'></select>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{PAYMENT_TYPE}_:</label>
        <div class='col-md-8'>
          %PAYMENT_METHOD_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='IP'>IP:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='IP' id='IP'>%IP%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='docs'>_{DOCUMENTATION}_:</label>
        <div class='col-sm-8'>
          <div class='input-group'>
            <input type='text' class='form-control' name='docs' id='docs' value='%DOCS%'>
            <div class='input-group-append'>
              <a id='link' class='btn input-group-button' href='%DOCS%' target='_blank'>
                <i class='fa fa-book'></i>
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='STATUS'>_{LOGON}_</label>
        <div class='col-md-8'>
          <div class='form-check'>
          <input id='STATUS' type='checkbox' name='STATUS' data-return='1' value='1' data-checked='%ACTIVE%'>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>

<script>
  try {
    var arr = JSON.parse('%JSON_LIST%');
  }
  catch (err) {
    console.log('JSON parse error.');
  }

  jQuery(function () {
    var select_module = jQuery('#MODULE');
    select_module.change(function () {
      var module = select_module.val();
      jQuery('#paysys_id').val(arr[module]['ID']);
      jQuery('#paysys_name').val(arr[module]['NAME']);
      jQuery('#IP').val(arr[module]['IP']);
      jQuery('#docs').val(arr[module]['DOCS']);
      jQuery('#link').attr('href', arr[module]['DOCS']);

      if (arr[module]['SUBSYSTEMS'] && typeof arr[module]['SUBSYSTEMS'] === 'object') {
        jQuery('#SUBSYSTEM_CONTAINER').removeAttr('hidden');
        arr[module]['SUBSYSTEMS']['0'] = '_{DEFAULT_SUBSYSTEM}_';

        var selectElement = jQuery('#SUBSYSTEM_ID');
        selectElement.empty();

        jQuery.each(arr[module]['SUBSYSTEMS'], function(value, text) {
          selectElement.append(jQuery('<option>', {
            value: value,
            text: text
          }));
        });
      }
      else {
        jQuery('#SUBSYSTEM_CONTAINER').attr('hidden', true);
      }
    });
  });

  if(jQuery('#PAY_SYSTEM_CONTAINER').is(':hidden')){
    jQuery('#create_payment_method').remove();
  }
</script>
