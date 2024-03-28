<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index' value='$index'>

<div class='card card-primary card-outline box-form'>
<div class='card-header with-border text-primary'>_{RULES_LIST}_</div>
<div class='card-body'>
        <div class='form-group'>
			<label class='col-md-3 control-label'>_{RULE}_</label>
			<div class='col-md-9'>
			    %RULE_SELECT%
			</div>
		</div>
</div>

<div class='card-footer'>
	<button type='submit' class='btn btn-primary'>_{SELECT}_</button>
</div>

</div>

</form>