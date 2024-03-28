<form id='form_user_contract' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index' />
  <input type='hidden' name='UID' value='$FORM{UID}' />
  <input type='hidden' name='chg' value='$FORM{chg}' />
  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ADDITION}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='NAME'>_{NAME}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%NAME%'  name='NAME'  id='NAME'  />
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='NUMBER'>_{NUMBER}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%NUMBER%'  name='NUMBER'  id='NUMBER'  />
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input type='text' class='form-control datepicker' value='%DATE%'  name='DATE'  id='DATE'  />
            <div class='input-group-append'>
              <div class='btn input-group-button rounded-left-0 text-blue'>
                <i class="fa fa-calendar"></i>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='TYPE'>_{TYPE}_</label>
        <div class='col-md-9'>%TYPE_SEL%</div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>