<form action='$SELF_URL' METHOD='POST' name='form_card_add'>
  <div class='card card-secondary'>
    <div class='card-header with-border'>
      <h4 class='card-title'>
        _{ICARDS}_
      </h4>
    </div>
    <div class='card-body form'>
      <input type='hidden' name='sid' value='%sid%'>
      <input type='hidden' name='index' value='$index'>
      <input type='hidden' name='UID' value='%UID%'>

      <div class='form-group row %SERIAL_HIDDEN%'>
        <label class='col-sm-4 col-md-4' for='SERIAL'>_{NUMBER_AND_SERIA}_</label>
        <div class='col-sm-8 col-md-8'>
          <input class='form-control' type='text' name='SERIAL' value='%SERIAL%' id='SERIAL'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4' for='PIN'>PIN</label>
        <div class='col-sm-8 col-md-8'>
          <input class='form-control' type='text' name='PIN' id='PIN'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='add'
             value='_{ACTIVATE}_' ID='submitButton' onClick='showLoading()'>
    </div>
  </div>
</form>
