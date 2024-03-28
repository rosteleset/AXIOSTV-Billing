<form action='$SELF_URL' method='GET' name='stats' role='form'>
  <input type='hidden' name='sid' value='%SID%'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='UID' value='%UID%'>

  <div class='card card-default'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{FILTERS}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right'>_{DATE}_:</label>
        <div class='col-md-9'>
          %DATE_PICKER%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right'>_{SPEED}_:</label>
        <div class='col-md-9'>
          %DIMENSION%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='PAGE_ROWS'>_{ROWS}_:</label>
        <div class='col-md-9'>
          <input type='text' ID='PAGE_ROWS' name='PAGE_ROWS' size='3' value='%PAGE_ROWS%' class='form-control'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='ONLINE'>Online:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='ONLINE' name='ONLINE' %ONLINE% value='1'>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' ID='show' name='show' value='_{SHOW}_' class='btn btn-primary'>
    </div>
  </div>
</form>