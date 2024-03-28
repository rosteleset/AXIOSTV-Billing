<form method='POST' action=$SELF_URL class='form-horizontal'>

<input type='hidden' name='index' value=$index>

<div class='box box-primary box-form'>
<div class='box-header with-border'>_{BALANCE}_</div>
<div class='box-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{CASHBOX}_</label>
    <div class='col-md-9'>
      %CASHBOX_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>Тип расхода</label>
    <div class='col-md-9'>
      %SPENDING_TYPE_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>Тип прихода</label>
    <div class='col-md-9'>
      %COMING_TYPE_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{FROM}_ _{DATE}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control datepicker' name='FROM_DATE' value='%FROM_DATE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{TO}_ _{DATE}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control datepicker' name='TO_DATE' value='%TO_DATE%'>
    </div>
  </div>
</div>
<div class='box-footer'>
  <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
</div>

</div>

</form>

<div class='row'>
<div class='form-group'>
  <div class='col-md-6'>%COMING_TABLE%</div>
  <div class='col-md-6'>%SPENDING_TABLE%</div>
</div>
</div>
<div class='row'>
<div class='form-group'>
  <div class='col-md-6'>%TOTAL_COMING_TABLE%</div>
  <div class='col-md-6'>%TOTAL_SPENDING_TABLE%</div>
</div>
</div>
<div class='col-md-4'>

    <div class='box box-primary'>
    <div class='box-header with-border'>
        <div class='row'>
            <div class='col-xs-3'>
            <i class='glyphicon glyphicon-plus fa-5x'></i>
            </div>
            <div class='col-xs-9 text-right'>
                <div style='font-size: 40px'>%TOTAL_COMING%</div>
             </div>
        </div>
    </div>
    </div>
</div>
<div class='col-md-4'>
    <div class='box box-danger'>
        <div class='box-header with-border'>
            <div class='row'>
            <div class='col-xs-3'>
                <i class='glyphicon glyphicon-minus fa-5x'></i>
             </div>
             <div class='col-xs-9 text-right'>
                <div style='font-size: 40px'>%TOTAL_SPENDING%</div>
             </div>
            </div>
        </div>
    </div>
</div>
<div class='col-md-4'>
    <div class='box box-success'>
        <div class='box-header with-border'>
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
%CHART%
