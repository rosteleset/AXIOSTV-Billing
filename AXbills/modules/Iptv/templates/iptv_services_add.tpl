<form action='%SELF_URL%' method='post' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='$FORM{chg}'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SERVICES}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='NUM' class='control-label col-md-3'>_{NUM}_:</label>
        <div class='col-md-4'>
          <input id='NUM' name='NUM' value='%ID%' placeholder='%ID%' class='form-control' type='text' disabled>
        </div>
        <label for='NUM' class='control-label col-md-5'>_{PLUGIN_VERSION}_: %MODULE_VERSION%</label>
      </div>

      <div class='form-group row'>
        <label for='NAME' class='control-label col-md-3'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input id='NAME' name='NAME' value='%NAME%' placeholder='_{NAME}_' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='MODULE' class='control-label col-md-3'>Plug-in:</label>
        <div class='col-md-9'>
          <input id='MODULE' name='MODULE' value='%MODULE%' placeholder='%MODULE%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='USER_PORTAL' class='control-label col-md-3'>_{USER}_ PORTAL:</label>
        <div class='col-md-9'>
          %USER_PORTAL_SEL%
        </div>
      </div>

      <div class='form-group custom-control custom-checkbox'>
        <input class='custom-control-input' type='checkbox' id='STATUS' name='STATUS' %STATUS% value='1'>
        <label for='STATUS' class='custom-control-label'>_{DISABLE}_</label>
      </div>

      <div class='form-group row'>
        <label for='PROVIDER_PORTAL_URL' class='control-label col-md-3'>_{PROVIDER_PORTAL_URL}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input id='PROVIDER_PORTAL_URL' name='PROVIDER_PORTAL_URL' value='%PROVIDER_PORTAL_URL%'
                   class='form-control' type='text'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span id='basic-addon2'>%PROVIDER_PORTAL_BUTTON%</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='card collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{AUTH}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label for='URL' class='control-label col-md-3'>URL:</label>
            <div class='col-md-9'>
              <input id='URL' name='URL' value='%URL%' placeholder='%URL%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='LOGIN' class='control-label col-md-3'>_{LOGIN}_:</label>
            <div class='col-md-9'>
              <input id='LOGIN' name='LOGIN' value='%LOGIN%' placeholder='%LOGIN%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='PASSWORD' class='control-label col-md-3'>_{PASSWD}_:</label>
            <div class='col-md-9'>
              <input id='PASSWORD' name='PASSWORD' class='form-control' type='password'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='DEBUG' class='control-label col-md-3'>DEBUG:</label>
            <div class='col-md-9'>
              %DEBUG_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label for='DEBUG_FILE' class='control-label col-md-3'>DEBUG _{FILE}_:</label>
            <div class='col-md-9'>
              <input id='DEBUG_FILE' name='DEBUG_FILE' value='%DEBUG_FILE%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='SUBSCRIBE_COUNT' class='control-label col-md-3'>_{COUNT}_:</label>
            <div class='col-md-9'>
              <input id='SUBSCRIBE_COUNT' name='SUBSCRIBE_COUNT' value='%SUBSCRIBE_COUNT%' class='form-control'
                     type='text'>
            </div>
          </div>
        </div>
      </div>

      %EXTRA_PARAMS%

      <div class='form-group row'>
        <div class='col-sm-12 col-md-12'>
          <textarea id='COMMENT' name='COMMENT' cols='50' rows='4' class='form-control' placeholder='_{COMMENTS}_'>%COMMENT%</textarea>
        </div>
      </div>

      <div class='form-group text-center'>
        %SERVICE_TEST% %TP_IMPORT% %CHANNEL_IMPORT% %CONSOLE% %SERVICE_PARAMS%
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
