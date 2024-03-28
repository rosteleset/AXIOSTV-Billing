<form method='POST' action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>


  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{STATUS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='NAME' id='NAME' value='%NAME%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='READINESS'>_{READINESS}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='number' class='form-control' name='READINESS' id='READINESS' value='%READINESS%'>
            <div class='input-group-append'>
              <div class='input-group-text'>%</div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COLOR'>_{COLOR}_:</label>
        <div class='col-md-8'>
          <input type='color' class='form-control' name='COLOR' id='COLOR' value='%COLOR%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ICON'>_{ICON}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='ICON' id='ICON' value='%ICON%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TASK_CLOSED'>_{TASK_CLOSED}_:</label>
        <div class='col-md-8'>
          <div class='form-check text-left'>
            <input type='checkbox' class='form-check-input' id='TASK_CLOSED' name='TASK_CLOSED' %CHECKED% value='1'>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
    </div>
  </div>

</form>