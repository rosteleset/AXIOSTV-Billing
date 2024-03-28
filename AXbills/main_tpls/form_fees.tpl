<form action='$SELF_URL' method='post' ID='user' name=user role='form' onsubmit=\"postthread('submitbutton');\">
  <input type=hidden name=UID value='%UID%'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=subf value='$FORM{subf}'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{FEES}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-2 col-md-3 col-form-label text-md-right required' for='SUM'>_{SUM}_:</label>
        <div class='col-sm-10 col-md-9'>
          <input autofocus id='SUM' name='SUM' value='$FORM{SUM}' placeholder='$FORM{SUM}' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='DESCRIBE'>_{DESCRIBE}_:</label>
        <div class='col-sm-10 col-md-9'>
          <input id='DESCRIBE' type='text' name='DESCRIBE' value='%DESCRIBE%' class='form-control'
                 maxlength='%MAX_LENGTH_DSC%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='INNER_DESCRIBE'>_{INNER}_:</label>
        <div class='col-sm-10 col-md-9'>
          <input id='INNER_DESCRIBE' type='text' name='INNER_DESCRIBE' value='%INNER_DESCRIBE%'
                 class='form-control' maxlength='%MAX_LENGTH_INNER_DESCRIBE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='METHOD'>_{TYPE}_:</label>
        <div class='col-sm-10 col-md-9'>
          %SEL_METHOD%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='CURRENCY'>_{CURRENCY}_ (_{EXCHANGE_RATE}_):</label>
        <div class='col-sm-10 col-md-9'>
          %SEL_ER%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-2 col-md-3 col-form-label text-md-right'>_{BILL}_:</label>
        <div class='col-sm-10 col-md-9'>
          %EXT_DATA_FORM%
        </div>
      </div>

      <div class='col-sm-12 col-md-12'>
        <div class='form-group row'>
          %PERIOD_FORM%
        </div>
      </div>

    </div>

    %SHEDULE_FORM%

  </div>
  %DOCS_FEES_ELEMENT%

  <div class='card-footer'>
    <input type=submit name='take' value='_{TAKE}_' class='btn btn-primary double_click_check' id='submitbutton'>
  </div>


  </div>
</form>
