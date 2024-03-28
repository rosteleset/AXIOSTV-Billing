<form class='form-horizontal' id='voip_recalculate'>
  <input type=hidden name='index' value=$index>
  <input type=hidden name='UID' value='%UID%'>
  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{RECALCULATE}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div id='_main' class='card-body'>
      <div class='form-group row'>
        <label class='col-md-1 control-label'>_{FROM}_</label>
        <div class='col-md-11'>
          %FROM_DATE%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-1 control-label'>_{TO}_:</label>
        <div class='col-md-11'>
          %TO_DATE%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name='recalc' value='_{RECALCULATE}_'>
    </div>
  </div>
</form>
