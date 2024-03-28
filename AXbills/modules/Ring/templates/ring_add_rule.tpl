<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index' value='%INDEX%'>
<input type='hidden' name='ACTION_TYPE' value=%ACTION_TYPE%>
<input type='hidden' name='ID' value=%ID%>

<div class='card card-primary card-outline box-form'>
<div class='card-header with-border text-primary'>
	<h4 class='card-title table-caption'>_{RULE}_</h4>
</div>

<div class='card-body'>

	<div class='form-group'>
		<label class='control-label col-md-3 required'>_{NAME}_</label>
		<div class='col-md-9'>
			<input class='form-control' required placeholder='_{NAME}_' name='NAME' value='%NAME%'>
		</div>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3 required'>_{TIME}_ _{BEGIN}_</label>
		<div class='col-md-9'>
			%TIME_START%
	 </div>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3 required'>_{TIME}_ _{END}_</label>
		<div class='col-md-9'>
			%TIME_END%
	 </div>
	</div>

	<div class='form-group'>
	  <div class='checkbox'>
      <label>
        <input type='checkbox' name='EVERY_MONTH' %EVERY_MONTH%>_{EVERY_MONTH}_
      </label>
    </div>
  </div>

	<div class='form-group'>
   		<label class='col-md-3 control-label required'>_{FILE}_</label>
   	<div class='col-md-7'>%FILE_SELECT%</div>
   	<div class='col-md-2'>
   		<a href='%UPLOAD_FILE%' class='btn btn-primary'>
  			<span class='fa fa-plus' aria-hidden='true'></span>
		</a>
	</div>
   </div>

   <div class='form-group'>
		<label class='control-label col-md-3 '>_{TEXT}_</label>
		<div class='col-md-9'>
			<textarea class='form-control' placeholder='_MESSAGE' name='MESSAGE'>%MESSAGE%</textarea>
		</div>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3'>_{COMMENTS}_</label>
		<div class='col-md-9'>
			<textarea class='form-control' placeholder='_COMMENTS' name='COMMENTS'>%COMMENTS%</textarea>
		</div>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3'>_{UPDATE_DAY}_</label>
		<div class='col-md-9'>
			<input type='text' class='form-control' name='UPDATE_DAY' value='%UPDATE_DAY%'>

		</div>
	</div>

	<div class='form-group'>
		<label class='control-label col-md-3'>_{SQL_QUERY}_</label>
		<div class='col-md-9'>
			<textarea class='form-control' placeholder='_{SQL_QUERY}_' name='SQL_QUERY'>%SQL_QUERY%</textarea>
		</div>
	</div>

</div>

<div class='card-footer'>
	<button type='submit' class='btn btn-primary'>%BUTTON%</button>
</div>

</div>


</form>
