<form action='https://money.idram.am/payment.aspx' method='POST'>
	<input type='hidden' name='EDP_LANGUAGE' value='%LANGUAGE%'>
	<input type='hidden' name='EDP_REC_ACCOUNT' value='%ACCOUNT%'>
	<input type='hidden' name='EDP_DESCRIPTION' value='%DESCRIBE%'>
	<input type='hidden' name='EDP_AMOUNT' value='%SUM%'>
	<input type='hidden' name='EDP_BILL_NO' value='%OPERATION_ID%'>
	<input type='hidden' name='UID' value='%UID%'>

<div class='card box-primary'>
    <div class='card-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='card-body'>
  <div class='form-group'>
      <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
    <label class='col-md-6 control-label'>%OPERATION_ID%</label>
  </div>
    
  <div class='form-group'>
      <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
    <label class='col-md-6 control-label'>IDRAM</label>
  </div>
    
  <div class='form-group'>
      <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
    <label class='control-label col-md-6'> %SUM% </label>
  </div>
</div>
<div class='card-footer'>
    <input class='btn btn-primary' type=submit value=_{PAY}_>
 </div>
</div>    




</form>
