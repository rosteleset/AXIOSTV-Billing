<form class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
  <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'><h3 class='card-title'>_{PERIOD}_</h3>
        <div class='card-tools float-right'>
        <button type='button' class='btn btn-secondary btn-xs' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>  

        <div class='form-group row' %DATE_FIELD%>
          <label class='control-label col-md-2' for='FROM_DATE'>_{FROM}_</label>
          <div class='col-md-4'>
            <input class='form-control' data-provide='datepicker' data-date-format="yyyy-mm-dd" value="%FROM_DATE%" name='FROM_DATE'>
          </div>
          <label class='control-label col-md-2' for='TO_DATE'>_{TO}_</label>
          <div class='col-md-4'>
            <input class='form-control' data-provide='datepicker' data-date-format="yyyy-mm-dd" value="%TO_DATE%" name='TO_DATE'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-2' for='ACTION'>_{ACTION}_</label>
          <div class='col-md-10'>
            %ACTION_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-2' for='NAME_id'>Hotspot</label>
          <div class='col-md-10'>
            <input type='text' class='form-control' value='%HOSTNAME%' name='HOSTNAME' id='NAME_id'/>
          </div>
        </div>

      </div>
      <div class='card-footer'>
        <input type=submit name=search value='_{SHOW}_' class='btn btn-primary'>
      </div>  
  </div>
</form>
