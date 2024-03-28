<form class='form-horizontal' action='$SELF_URL' METHOD='POST'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='search_form' value='1'>
  %HIDDEN_FIELDS%
  <div class='card card-primary card-outline box-form card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SEARCH}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-3 control-label' for='PAGE_ROWS'>_{ROWS}_:</label>
        <div class='col-sm-9'>
          <input id='PAGE_ROWS' name='PAGE_ROWS' value='$PAGE_ROWS' class='form-control' type='text'>
        </div>
      </div>
      %SEARCH_FORM%
    </div>
    <div class='card-footer'>
      <input type='submit' name='search' value='_{SEARCH}_' class='btn btn-primary'>
    </div>
  </div>
</form>
