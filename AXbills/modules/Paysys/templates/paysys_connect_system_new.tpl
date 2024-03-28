<form name='PAYSYS_CONNECT_SYSTEM' id='form_PAYSYS_CONNECT_SYSTEM' method='post'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='OLD_NAME' value='%NAME%'>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h4>_{PAY_SYSTEM}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row %HIDE_SELECT%'>
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
          <input type='text' class='form-control' name='NAME' value='%NAME%'
                 id='paysys_name' required pattern='[A-Za-z0-9_]{1,30}' data-tooltip='Только лат. буквы, цифры и подчеркивание'>
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
            <span class='input-group-text'><a id='link' href='%DOCS%' target='_blank'><i class='fa fa-book'></i></a></span>
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
    });
  });

  if(jQuery('.form-group').is(':hidden')){
    jQuery('#create_payment_method').remove();
  }
</script>