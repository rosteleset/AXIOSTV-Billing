<form method='POST' action='$SELF_URL'>
<input type='hidden' name='SUM' value='$FORM{SUM}' />
<input type='hidden' name='sid' value='$FORM{sid}'/>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'/>
<input type='hidden' name='index' value='$index' />
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}' />
<input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}' />


<div class='card box-primary'>
<div class='card-header with-border text-center'>Qiwi</div>
<div class='card-body'>
	<div class='form-group'>
		<label class='col-md-6 text-center'>Operation ID:</label>
		<label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
	</div>

	<div class='form-group'>
        <label class='col-md-6 text-center'>_{SUM}_:</label>
		<label class='col-md-6 control-label'>$FORM{SUM}</label>
	</div>

	<div class='form-group'>
        <label class='col-md-6 text-center'>_{PHONE}_, десятизначный номер абонента (Пример: 9029283847):</label>
		<div class='col-md-6'><input class='form-control' type='input' name='PHONE' value='%PHONE%'></div>
	</div>
</div>
<div class='card-footer'>
    <input class='btn btn-primary' type=submit value='_{GET_INVOICE}_' name=send_invoice>
</div>

</div>

</form>
