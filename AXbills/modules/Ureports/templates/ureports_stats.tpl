<form id='stats' class='form form-horizontal form-main' action=$SELF_URL method='POST'>
  <input type='hidden' name='sid' value='%SID%'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='UIDS' value='%UIDS%'>
  <input type='hidden' name='UID' value='%UID%'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{FILTERS}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-2 col-sm-2 control-label'>_{PERIOD}_:</label>
        <div class='col-md-8 col-sm-8'>
          %PERIOD%
        </div>
        <div class='col-md-2'>
          <input type='submit' name='show' value='_{SHOW}_' class='btn btn-primary' form='stats'/>
        </div>
      </div>
    </div>
  </div>
</form>