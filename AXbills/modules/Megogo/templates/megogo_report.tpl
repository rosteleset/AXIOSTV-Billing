<form action=$SELF_URL METHOD=POST>
<input type='hidden' name='index' value=%INDEX%>

<div class='box box-form box-primary form-horizontal'>

<div class='box-header with-border'>_{USED}_</div>
<div class='box-body'>
<div class='form-group'>
		<label class='col-md-3 control-label'>_{YEAR}_</label>
		<div class='col-md-9'> %YEARS% </div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{MONTH}_</label>
		<div class='col-md-9'> %MONTHES% </div>
	</div>
</div>
<div class='box-footer'>
	<button type='submit' class='btn btn-primary'>_{SHOW}_</button>
</div>

</div>
</form>