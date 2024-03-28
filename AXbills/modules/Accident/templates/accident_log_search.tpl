<form action='%SELF_URL%' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='search_form' value='1'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SEARCH}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-4'>_{PRIORITY}_:</label>
        <div class='col-md-8 col-sm-8'>
          %SELECT_PRIORITY%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-4'>_{STATUS}_:</label>
        <div class='col-md-8 col-sm-8'>
          %SELECT_STATUS%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-4'>_{ADMIN}_:</label>
        <div class='col-md-8 col-sm-8'>
          %SELECT_ADMIN%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='REGISTRATION'>_{DATE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='hidden' name='FROM_DATE' value='%FROM_DATE%' id='FROM_DATE'>
            <input type='hidden' name='TO_DATE' value='%TO_DATE%' id='TO_DATE'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' %DATE_PICKER_CHECKED% class='form-control-static' data-input-enables='FROM_DATE_TO_DATE,FROM_DATE,TO_DATE'/>
              </span>
            </div>
            %DATE_PICKER%
          </div>
        </div>
      </div>

      %SELECT_ADDRESS%
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary float-right' type='submit' name='search' value='_{SEARCH}_'>
    </div>
  </div>
</form>

