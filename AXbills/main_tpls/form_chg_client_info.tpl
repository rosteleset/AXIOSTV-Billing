<form action='%SELF_URL%' method='post'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=sid value='$sid'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border text-center'>
      <h4 class='card-title'>_{DATA_CHANGE}_</h4>
    </div>
    <div class='card-body'>
      %MESSAGE_CHG%

      <div id='simple_fio'>
        <div class='form-group row' %FIO_HAS_ERROR% %FIO_HIDDEN%>
          <label class='control-label col-md-3 required' for='FIO'>_{FIO}_</label>
          <div class='col-md-9'>
            <div class='input-group'>
              <input name='FIO' class='form-control' %FIO_READONLY% %FIO_DISABLE% id='FIO' value='%FIO%'>
              <span class='input-group-append'>
                  <button id='show_fio' type='button' %FIO_DISABLE% class='btn btn-default' tabindex='-1'>
                    <i class='fa fa-bars'></i>
                  </button>
                </span>
            </div>
          </div>
        </div>
      </div>

      <div id='full_fio' style='display:none'>
        <div class='form-group row'>
          <label class='control-label col-md-4' for='FIO1'>_{FIO1}_:</label>
          <div class='col-md-8'>
            <div class='input-group'>
              <input name='FIO1' class='form-control' id='FIO1' value='%FIO1%'>
              <span class='input-group-append'>
                <button id='hide_fio' type='button' class='btn btn-default' tabindex='-1'>
                  <i class='fa fa-reply'></i>
                </button>
              </span>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-4' for='FIO2'>_{FIO2}_:</label>
          <div class='col-md-8'>
            <div class='input-group'>
              <input name='FIO2' class='form-control' id='FIO2' value='%FIO2%'>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-4' for='FIO3'>_{FIO3}_:</label>
          <div class='col-md-8'>
            <div class='input-group'>
              <input name='FIO3' class='form-control' id='FIO3' value='%FIO3%'>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row %PHONE_HAS_ERROR% %PHONE_HIDDEN%'>
        <label class='col-md-4 required control-label' for='PHONE'>_{PHONE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type=text name=PHONE id='PHONE' value='%PHONE_ALL%' class='form-control' %PHONE_DISABLE%>
          </div>
        </div>
      </div>

      <div class='form-group row %CELL_PHONE_HAS_ERROR% %CELL_PHONE_HIDDEN%'>
        <label class='col-md-4 required control-label' for=CELL_PHONE>_{CELL_PHONE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type=text name=CELL_PHONE id=CELL_PHONE value='%CELL_PHONE_ALL%' class='form-control' %CELL_PHONE_DISABLE%>
          </div>
        </div>
      </div>

      <div class='form-group row %EMAIL_HAS_ERROR% %EMAIL_HIDDEN%'>
        <label class='col-md-4 control-label required' for=EMAIL>E-mail:</label>
        <div class='col-md-8 %EMAIL_HAS_ERROR% %EMAIL_HIDDEN%'>
          <div class='input-group'>
            <input type=text name=EMAIL id=EMAIL value='%EMAIL%' class='form-control' %EMAIL_DISABLE%>
          </div>
        </div>
      </div>
      <hr/>

      %ADDRESS_SEL%
      %INFO_FIELDS%
      %INFO_FIELDS_POPUP%

    </div>

    <div class='card-footer'>
      %BTN_TO_MODAL%
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary text-center'>
    </div>
  </div>
</form>

<script type='text/javascript'>
  jQuery('#show_fio').click(function () {
    jQuery('#simple_fio').fadeOut(200);
    jQuery('#full_fio').delay(201).fadeIn(300);
  });

  jQuery('#hide_fio').click(function () {
    jQuery('#full_fio').fadeOut(200);
    jQuery('#simple_fio').delay(201).fadeIn(300);
  });
</script>