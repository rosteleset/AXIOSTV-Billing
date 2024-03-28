<form method='POST' action=$SELF_URL class='form-horizontal'>

  <input type='hidden' name='index' value=$index>

  <div class='card box-primary card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title table-caption'>_{BALANCE}_ _{IN_CASHBOX}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{CASHBOX}_</label>
        <div class='col-md-9'>
          %CASHBOX_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{SPENDING}_</label>
        <div class='col-md-9'>
          %SPENDING_TYPE_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{COMING}_</label>
        <div class='col-md-9'>
          %COMING_TYPE_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{DATE}_</label>
        <div class='col-md-9'>
          %PERIOD%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
    </div>

  </div>

</form>

<div class='row'>
  <div class='col-md-6'>%COMING_TABLE%</div>
  <div class='col-md-6'>%SPENDING_TABLE%</div>

</div>
<div class='row'>
  <div class='col-md-6'>%TOTAL_COMING_TABLE%</div>
  <div class='col-md-6'>%TOTAL_SPENDING_TABLE%</div>
</div>
<div class='row'>
  <div class='col-md-4'>
    <div class='card card-primary'>
      <div class='card-header with-border'>
        <div class='row'>
          <div class='col-xs-3'>
            <i class='fa fa-plus fa-5x'></i>
          </div>
          <div class='col-xs-9 text-right'>
            <div style='font-size: 40px'>%TOTAL_COMING%</div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='col-md-4'>
    <div class='card card-danger'>
      <div class='card-header with-border'>
        <div class='row'>
          <div class='col-xs-3'>
            <i class='fa fa-minus fa-5x'></i>
          </div>
          <div class='col-xs-9 text-right'>
            <div style='font-size: 40px'>%TOTAL_SPENDING%</div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='col-md-4'>
    <div class='card card-success'>
      <div class='card-header with-border'>
        <div class='row'>
          <div class='col-xs-3'>
            <i class='fa fa-calculator fa-5x'></i>
          </div>
          <div class='col-xs-9 text-right'>
            <div style='font-size: 40px'>%BALANCE%</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
%CHART%
