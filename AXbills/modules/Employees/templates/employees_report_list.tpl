<form action='$SELF_URL' METHOD=POST>

  <input type='hidden' name='index' value=$index>

  <div class='card card-primary card-outline form-horizontal '>

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
            <label class='col-md-3 control-label'>_{DATE}_ </label>
            <div class='col-md-9'>
              %DATE%
            </div>
          </div>
        </div>
        <div class='col-md-6'>
          <div class='form-group row' style='display: %HIDE_SOURCE_SELECT%'>
            <label class='col-md-3 control-label'>
              _{SHOW}_ _{DISABLED}_
              <input type='checkbox' name='disable'>
            </label>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary btn-block' value='_{ACCEPT}_' name='_{ACCEPT}_'>
    </div>
  </div>

</form>