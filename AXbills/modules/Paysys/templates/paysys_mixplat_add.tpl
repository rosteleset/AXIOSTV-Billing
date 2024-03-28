<form action='https://client.mixplat.ru/api/mc.init' method='GET'>
<input type='hidden' name='phone' value='%PHONE%'>
<input type='hidden' name='amount' value='$FORM{SUM}'>
<input type='hidden' name='merchant_order_id' value='$FORM{OPERATION_ID}'>
<input type='hidden' name='test' value='%TEST%'>
<input type='hidden' name='service_id' value='111'>
<input type='hidden' name='currency' value='RUB'>
<input type='hidden' name='sign' value='%SIGNATURE%'>


<div class='card box-primary'>
    <div class='card-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='card-body'>
  <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
  </div>
  <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>Mixplat</label>
  </div>
  <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{SUM}_:</label>
        <label class='col-md-6 control-label'>$FORM{SUM}</label>
  </div>
</div>

<div class='card-footer'>
   <input class='btn btn-primary' type='submit' value=_{PAY}_>
</div>
</div>

</form>