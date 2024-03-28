<form action='%SELF_URL%' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='search_form' value='1'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title '>_{SET_PARAMS}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body row'>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{SPRINT_TIMETRACK}_:</label>
        <div class='col-md-8'>
          %SELECT_SPRINT%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{RESPONSIBLE}_:</label>
        <div class='col-md-8'>
          %SELECT_RESPONSIBLE%
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input class='btn btn-primary btn-block' type='submit' name='search' value='_{SHOW}_'>
    </div>
  </div>
</form>