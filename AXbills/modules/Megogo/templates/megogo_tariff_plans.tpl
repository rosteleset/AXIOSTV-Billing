<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value=%ID%>
<input type='hidden' name='action' value=%ACTION%>

<div class='box box-theme box-form'>
<div class='box-header with-border text-primary'>$lang{TP}</div>

<div class='box-body'>

	<div class='form-group'>
		<label class='control-label col-md-3'>$lang{TP}</label>
		<div class='col-md-9'><input class='form-control' required name='NAME' value='%NAME%'></div>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3'>$lang{AMOUNT}($lang{IN_MONTH})</label>
		<div class='col-md-9'><input class='form-control' required name='AMOUNT' value='%AMOUNT%'></div>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3'>$lang{SERVICEID}</label>
		<div class='col-md-9'><input class='form-control' required name='SERVICEID' value='%SERVICEID%'></div>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3'>$lang{SECONDARY}</label>
		<input type='checkbox' name='ADDITIONAL' %IS_ADDITIONAL%>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3'>$lang{FREE_PERIOD}</label>
		<input type='checkbox' name='FREE_PERIOD' %IS_FREE%>
	</div>

</div>

<div class='box-footer'>
	<button type='submit' class='btn btn-primary'>%BUTTON%</button>
</div>

</div>
</form>