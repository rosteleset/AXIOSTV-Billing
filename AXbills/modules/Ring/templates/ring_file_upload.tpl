<form action=$SELF_URL METHOD=POST class='form-horizontal' enctype=multipart/form-data>

<input type='hidden' name='index' value=%INDEX%>

<div class='card card-primary card-outline box-form'>
<div class='card-header with-border text-primary'>_{UPLOAD}_</div>

<div class='card-body'>
	<label class='col-md-3'>_{FILE}_</label>
	<div class='col-md-9'><input type='file' name=FILE></div>
</div>

<div class='card-footer'>
	<button type='submit' class='btn btn-primary'>_{ADD}_</button>
</div>
</div>

</form>