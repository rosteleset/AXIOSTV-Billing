<form action=$SELF_URL name='inventory_form' method=GET class='form-horizontal'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=UID value='$FORM{UID}'>
  <input type=hidden name=ID value='$FORM{chg}'>

  <div class='card card-primary card-outline card-form p-0'>
    <div class='card-header with-border'><h4 class='card-title'>_{EQUIPMENT}_</h4></div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='HOSTNAME'>_{HOSTNAME}_</label>
        <div class='col-md-9'>
          <input type=text name=HOSTNAME value='%HOSTNAME%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='IP'>IP:</label>
        <div class='col-md-9'>
          <input type=text name=IP value='%IP%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='WEB_ACCESS_INFO'>WEB: _{ACCESS}_</label>
        <div class='col-md-9'>
          <input type=text name=WEB_ACCESS_INFO value='%WEB_ACCESS_INFO%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='ACCESS_INFO'>SSH: _{ACCESS}_</label>
        <div class='col-md-9'>
          <input type=text name=ACCESS_INFO value='%ACCESS_INFO%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='LOGIN'>_{LOGIN}_</label>
        <div class='col-md-9'>
          <input type=text name=LOGIN value='%LOGIN%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='PASSWORD'>_{PASSWD}_</label>
        <div class='col-md-9'>
          <input type=text name=PASSWORD value='%PASSWORD%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='SUPERPASSWORD'>root _{PASSWD}_</label>
        <div class='col-md-9'>
          <input type=text name=SUPERPASSWORD value='%SUPERPASSWORD%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='INTEGRATION_DATE'>_{INTEGRATION_DATE}_</label>
        <div class='col-md-9'>
          <input type=text name=INTEGRATION_DATE value='%INTEGRATION_DATE%' class='form-control datepicker'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='ADMIN_MAIL'>_{ADMIN_MAIL}_</label>
        <div class='col-md-9'>
          <input type=text name=ADMIN_MAIL value='%ADMIN_MAIL%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='BENCHMARK_INFO'>Benchmark _{INFO}_</label>
        <div class='col-md-9'>
          <input type=text name=BENCHMARK_INFO value='%BENCHMARK_INFO%' class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='RESPONSIBLE'>_{RESPONSIBLE}_</label>
        <div class='col-md-9'>
          %ADMINS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='STATUS_SEL'>_{STATUS}_</label>
        <div class='col-md-9'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea name=COMMENTS rows=4 class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>

    <div class='card border-top collapsed-card mb-0'>
      <div class='card-header with-border'>
        <h3 class='card-title'>Hardware</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        %HARDWARE%
      </div>
    </div>

    <div class='card border-top collapsed-card mb-0'>
      <div class='card-header with-border'>
        <h3 class='card-title'>Software</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        %SOFTWARE%
      </div>
    </div>

    <div class='card-footer'>
      <input type=submit name=%ACTION% value=%ACTION_LNG% class='btn btn-primary'> %DEL_BUTTON%
    </div>
  </div>

</form>
