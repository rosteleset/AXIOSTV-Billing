<form action='$SELF_URL' METHOD='POST' class='form-horizontal' name='msgs_export' id='msgs_export'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='UID' value='%UID%'/>
  <input type='hidden' name='PLUGIN' value='%PLUGIN%'/>
  <input type='hidden' name='export' value='1'/>

  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{EXPORT}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-9'>
          <input type='text' name='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%' class='form-control'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='MESSAGE'>_{MESSAGE}_:</label>
        <div class='col-md-9'>
            <textarea class='form-control' id='MESSAGE' name='MESSAGE' rows='3' class='form-control'>%MESSAGE%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='STATUS'>_{PRIORITY}_:</label>
        <div class='col-md-9'>
          %PRIORITY_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='STATUS'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='EXPORT_SYSTEM'>_{EXPORT}_:</label>
        <div class='col-md-9'>
          %EXPORT_SYSTEM_SEL%
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>