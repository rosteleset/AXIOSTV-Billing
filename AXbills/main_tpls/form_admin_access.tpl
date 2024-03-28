<form class='form-horizontal' action='$SELF_URL' method='post' role='form' id='form_admin_access'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{ACCESS}_</h3>
    </div>
    <div class='card-body'>
      <input type=hidden name='index' value='$index'>
      <input type=hidden name='AID' value='%AID%'>
      <input type=hidden name='ID' value='$FORM{chg}'>
      <input type=hidden name='subf' value='$FORM{subf}'>

      <div class='form-group'>
        <div class='row'>
          <div class='col-sm-12 col-md-4 row'>
            <label class='col-md-3 control-label' for='DAYS'>_{DAY}_</label>
            <div class='input-group col-md-9'>
              %SEL_DAYS%
            </div>
          </div>

          <div class='col-sm-12 col-md-4 row'>
            <label class='control-label col-md-3' for='BEGIN'>_{BEGIN}_</label>
            <div class='input-group col-md-9'>
              <input id='BEGIN' name='BEGIN' value='%BEGIN%' placeholder='%BEGIN%' class='form-control'
                     type='text'>
            </div>
          </div>

          <div class='col-sm-12 col-md-4 row'>
            <label class='control-label col-md-3' for='END'>_{END}_</label>
            <div class='input-group col-md-9'>
              <input id='END' name='END' value='%END%' placeholder='%END%' class='form-control' type='text'>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <div class='row'>
          <div class='col-sm-12 col-md-4 row'>
            <label class='control-label col-md-3' for='IP'>_{ALLOW}_ IP</label>
            <div class='input-group col-md-9'>
              <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control' type='text'>
            </div>
          </div>

          <div class='col-sm-12 col-md-4 row'>
            <label class='control-label col-md-3' for='BIT_MASK'>MASK</label>
            <div class='input-group col-md-9'>
              %BIT_MASK_SEL%
            </div>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <div class='row'>
          <div class='col-sm-12 col-md-12'>
            <div class='input-group col-md-12'>
              <textarea id='COMMENTS' name='COMMENTS' placeholder='_{COMMENTS}_' class='form-control'
                        rows=3>%COMMENTS%</textarea>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <div class='form-check'>
          <div class='form-group custom-control custom-checkbox'>
            <input id='DISABLE' name='DISABLE' class='form-check-input' value='1' data-return='1' type='checkbox' %DISABLE%>
            <label class='form-check-label' for='DISABLE'>_{DISABLE}_</label>
          </div>
        </div>
      </div>

      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
