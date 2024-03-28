<form class='form form-horizontal ' action=$SELF_URL method='POST'>
  <input type='hidden' name='DATE' value='%DATE%'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='day' value='%day%'>

  <div class='card card-primary card-outline box-big-form'>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-2 col-form-label text-md-right'>_{POSITION}_:</label>
        <div class='col-md-3'>
          %POSITION%
        </div>
        <label class='col-md-2 col-form-label text-md-right'>_{DEPARTMENT}_:</label>
        <div class='col-md-3'>
          %DEPARTMENT%
        </div>
        <div class='col-md-2'>
          <div class='btn-group'>
            %BTN_LOAD_TO_MODAL%
            %BTN_CHART%
            %BTN_PRINT%
          </div>
        </div>
      </div>
    </div>
  </div>
  %TABLE%
  <input type='submit' name='change' value='_{CHANGE}_' class='btn btn-primary'>
</form>