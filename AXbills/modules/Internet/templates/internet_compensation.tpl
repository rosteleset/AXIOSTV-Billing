<div class='d-print-none'>

  <form action='$SELF_URL' method='POST' name='compensation' class='form-horizontal'>
    <div class='card card-primary card-outline container-md col-md-6'>
      <input type=hidden name='index' value='$index'>
      <input type=hidden name='UID' value='$FORM{UID}'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{COMPENSATION}_</h4>
      </div>
      <div class='card-body'>
        <div class='form-group row'>
          <label class='control-label col-md-3' for='FROM'>_{FROM}_:</label>
          <div class='col-md-9'>
            <input id='FROM' name='FROM_DATE' value='%FROM_DATE%' class='form-control datepicker' type='text'
                   autocomplete='off'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='TO'>_{TO}_:</label>
          <div class='col-md-9'>
            <input id='TO' name='TO_DATE' value='%TO_DATE%' class='form-control datepicker' type='text'
                   autocomplete='off'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='DESCRIBE'>_{DESCRIBE}_:</label>
          <div class='col-md-9'>
            <textarea class='form-control' id='DESCRIBE' name='DESCRIBE' rows='2'>%DESCRIBE%</textarea>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='INNER_DESCRIBE'>_{INNER}_ _{DESCRIBE}_:</label>
          <div class='col-md-9'>
            <textarea class='form-control' id='INNER_DESCRIBE' name='INNER_DESCRIBE'
                      rows='2'>%INNER_DESCRIBE%</textarea>
          </div>
        </div>
      </div>
      <div class='card-footer'>
        <input type='submit' class='btn btn-primary' name='add' value='_{COMPENSATION}_'>
      </div>
    </div>
  </form>
</div>
