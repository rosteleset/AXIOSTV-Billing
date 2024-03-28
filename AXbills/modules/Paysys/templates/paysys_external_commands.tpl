<form name='PAYSYS_EXTERNAL_COMMAND' class='form form-horizontal hidden-print form-main'>
  <input type='hidden' name='index' value=$index>
  <div class='card card-primary card-outline col-md-8 container'>

    <div class='card-header with-border'>_{EXTERNAL_COMMAND}_</div>

    <div class='card-body'>
      <div class='form-group align-content-center'>
        <label class='col-sm-12 col-md-12' for='PAYSYS_EXTERNAL_START_COMMAND'>_{START_COMMAND}_</label>
        <div class='col-md-12'>
          <textarea class='form-control' id='PAYSYS_EXTERNAL_START_COMMAND' name='PAYSYS_EXTERNAL_START_COMMAND'>%PAYSYS_EXTERNAL_START_COMMAND%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='PAYSYS_EXTERNAL_END_COMMAND'>_{END_COMMAND}_</label>
        <div class='col-md-12'>
          <textarea class='form-control' id='PAYSYS_EXTERNAL_END_COMMAND' name='PAYSYS_EXTERNAL_END_COMMAND'>%PAYSYS_EXTERNAL_END_COMMAND%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='PAYSYS_EXTERNAL_PAYMENT_MADE_COMMAND'>_{PAYMENT_COMMAND}_</label>
        <div class='col-md-12'>
          <textarea class='form-control' id='PAYSYS_EXTERNAL_PAYMENT_MADE_COMMAND' name='PAYSYS_EXTERNAL_PAYMENT_MADE_COMMAND'>%PAYSYS_EXTERNAL_PAYMENT_MADE_COMMAND%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='PAYSYS_EXTERNAL_ATTEMPTS'>_{ATTEMPTS}_</label>
        <div class='col-md-12'>
          <input type='number' class='form-control' id='PAYSYS_EXTERNAL_ATTEMPTS' name='PAYSYS_EXTERNAL_ATTEMPTS' value='%PAYSYS_EXTERNAL_ATTEMPTS%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='PAYSYS_EXTERNAL_TIME'>_{TIME}_ (_{IN}_ _{MINUTES}_)</label>
        <div class='col-md-12'>
          <input type='number' class='form-control' id='PAYSYS_EXTERNAL_TIME' name='PAYSYS_EXTERNAL_TIME' value='%PAYSYS_EXTERNAL_TIME%'>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LANG%'>
    </div>
  </div>
</form>