<form action='$SELF_URL' METHOD=POST>

  <input type='hidden' name='index' value='$index'>

  <div class='card card-primary card-outline form-horizontal'>
    <div class='card-header with-border'>
      <h4 class='card-title table-caption'>_{FILTERS}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i></button>
      </div>
    </div>

    <div class='card-body'>
      <div class='row align-items-center'>
        <div class='col-md-6'>
          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{ADMIN}_:</label>
            <div class='col-md-9'>
              %ADMIN_SELECT%
            </div>
          </div>
        </div>
        <div class='col-md-6'>
          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{DATE}_:</label>
            <div class='col-md-9'>
              %DATE_RANGE%
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name='FILTER' value='_{SEARCH}_' class='btn btn-primary btn-block'>
    </div>
  </div>

</form>