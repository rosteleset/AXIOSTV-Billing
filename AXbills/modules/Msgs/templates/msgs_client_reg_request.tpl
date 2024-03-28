<div class='row'>
  <div class='col-md-6 %FORM_COL_CLASSES%'>
    <FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name=reg_request_form class='form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type=hidden name=module value=Msgs>
      <input type=hidden name=REGISTRATION_REQUEST value=1>
      <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>

      <div class='card card-primary card-outline box-form center-block'>
        <div class='card-header with-border'><h4 class='card-title'>_{REGISTRATION}_</h4></div>

        <div class='card-body'>
          %CHECKED_ADDRESS_MESSAGE%
          <div class='row'>
            <div class='col-md-1'></div>
            <div class='col-md-11'>
              %ADDRESS_TPL%
            </div>
          </div>
          <hr/>

          <div class='form-group row'>
            <label class='control-label required col-md-3' for='FIO'>_{FIO}_</label>
            <div class='col-md-9'>
              <input type='text' id='FIO' name='FIO' value='%FIO%' required placeholder='%FIO%'
                     class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label required col-md-3' for='PHONE'>_{PHONE}_</label>
            <div class='col-md-9'>
              <input type='text' id='PHONE' name='PHONE' value='%PHONE%' required='required' placeholder='%PHONE%'
                     class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='EMAIL'>E-mail</label>
            <div class='col-md-9'>
              <input type='text' id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='account@mail.com'
                     class='form-control'>
            </div>
          </div>

          <hr/>

          <div class='form-group row'>
            <label class='control-label required col-md-3' for='CONNECTION_TIME'>_{CONNECTION_TIME}_</label>
            <div class='col-md-9'>
              <input type='text' id='CONNECTION_TIME' name='CONNECTION_TIME' required value='%CONNECTION_TIME%'
                     placeholder='%CONNECTION_TIME%' class='form-control datepicker with-time'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_</label>
            <div class='col-md-9'>
              <input type='text' id='SUBJECT' name='SUBJECT' value='_{REGISTRATION}_' readonly='readonly'
                     placeholder='%SUBJECT%'
                     class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
            <div class='col-md-9'>
              <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'
                        class='form-control'>%COMMENTS%</textarea>
            </div>
          </div>

          <hr/>

          %CAPTCHA%

        </div>

        <div class='card-footer'>
          <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
        </div>

      </div>
    </FORM>
  </div>

  <div class='col-md-6' data-visible='%MAP_VISIBLE%'>
    <div class='card card-primary card-outline'>
      <div class='card-body'>
        %MAPS%
        </div>
      </div>
  </div>
</div>