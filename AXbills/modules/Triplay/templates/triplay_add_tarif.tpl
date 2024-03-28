<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index' value=%INDEX%>
<input type='hidden' name='action' value=%ACTION%>
<input type='hidden' name='id' value=%ID%>

<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border text-primary'>_{TARIFF_PLAN}_</div>

<div class='card-body'>
	<div class='form-group'>
        <label class='col-md-3 control-label'>_{NAME}_</label>
		<div class='col-md-9'>
			<input type='text' required class='form-control' NAME='NAME' VALUE='%NAME%' >
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>Internet</label>
		<div class='col-md-9'>
			%INTERNET%
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>IPTV</label>
		<div class='col-md-9'>
			%IPTV%
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>VOIP</label>
		<div class='col-md-9'>
			%VOIP%
		</div>
	</div>
	<div class='form-group'>
        <label class='col-md-3 control-label'>_{COMMENTS}_</label>
		<div class='col-md-9'>
            <textarea class='form-control' placeholder='_{COMMENTS}_' name='COMMENT'>%COMMENT%</textarea>
		</div>
	</div>
</div>

<div class='card-footer'>
  <button type='submit' class='btn btn-primary'>%BUTTON%</button>
</div>

</div>