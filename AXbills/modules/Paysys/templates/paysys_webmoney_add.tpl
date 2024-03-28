<form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>

<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/>

<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
%TEST_MODE%

<div class='card box-primary'>
    <div class='card-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='card-body'>
    <div class='form-group'>
    	<label class='col-md-6 control-label text-center'>ID:</label>
    	<label class='col-md-6 control-label'>%LMI_PAYMENT_NO%</label>
    </div>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{SUM}_:</label>
    	<label class='col-md-6 control-label'>%LMI_PAYMENT_AMOUNT%</label>
    </div>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{DESCRIBE}_:</label>
    	<label class='col-md-6 control-label'>%DESCRIBE%</label>
    	<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>
    </div>
    <div class='form-group'>
        <label class='col-md-6 control-element text-center'>_{ACCOUNT}_:</label>
    	<label class='col-md-6 control-label'>%ACCOUNTS_SEL%</label>
    </div>
</div> 
    <div class='card-footer'>
        <input type='submit' class='btn btn-primary' value='_{ADD}_'>
    </div>   
</div>

</form>
