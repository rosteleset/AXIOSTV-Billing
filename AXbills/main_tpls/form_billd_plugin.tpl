<form action='$SELF_URL' METHOD='POST' class='form-horizontal' name=admin_form>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='ID' value='%ID%'>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>Billd</h4></div>
    <div class='card-body'>

      <div class='form-group'>
        <div class='row'>
          <div class='col-sm-12 col-md-4'>
            <div class='form-group row'>
              <label class='col-sm-2 col-form-label' for='PLUGIN_NAME'>_{NAME}_</label>
              <div class='col-sm-10 input-group'>
                <input id='PLUGIN_NAME' name='PLUGIN_NAME' value='%PLUGIN_NAME%' placeholder='_{PLUGIN_NAME}_' class='form-control' type='text'>
              </div>
            </div>
          </div>

          <div class='col-sm-12 col-md-4'>
            <div class='form-group row'>
              <label class='control-label col-sm-2' for='PERIOD'>_{PERIOD}_ (Sec:)</label>
              <div class='col-sm-10'>
                <input id='PERIOD' name='PERIOD' value='%PERIOD%' placeholder='300' class='form-control' type='text'>
              </div>
            </div>
          </div>

          <div class='col-sm-12 col-md-4'>
            <div class='form-group row'>
              <label class='col-form-label col-sm-2' for='STATUS'>_{STATUS}_</label>
              <div class='col-sm-10'>
                %STATUS_SEL%
              </div>
            </div>
          </div>

        </div>
      </div>

      <div class='form-group'>
        <div class='row'>
          <div class='col-sm-12 col-md-6'>
            <div class='form-group row'>
              <label class='col-form-label col-sm-2' for='THREADS'>_{THREADS}_</label>
              <div class='col-sm-10'>
                %THREADS_SEL%
              </div>
            </div>
          </div>
          <div class='col-sm-12 col-md-6'>
            <div class='form-group row'>
              <label class='col-form-label col-sm-2' for='PRIORITY'>_{PRIORITY}_</label>
              <div class='col-sm-10'>
                %PRIORITY_SEL%
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <div class='form-check'>
          <input class='form-check-input' id='MAKE_LOCK' name='MAKE_LOCK' value='1' %MAKE_LOCK% type='checkbox'>
          <label class='form-check-label' for='MAKE_LOCK'>_{LOCK}_</label>
        </div>
      </div>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>

