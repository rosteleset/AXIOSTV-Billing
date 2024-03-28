<form method='post' class='form'>

<input type='hidden' name='poll' value='$FORM{poll}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='LOGIN'   value='%LOGIN%'>
<input type='hidden' name='DISCUSSION' value='1'>

<div class='card card-primary card-outline'>
	<div class='card-header with-border text-primary'><h3>%SUBJECT%</h3></div>
	<div class='card-header with-border text-primary'><h3>%EXPIRATION_DATE%</h3></div>
	<div class='card-body text-left'>
		%MESSAGE%
	</div>
	<div class='card-footer'>
	  <div class='form-group'>
		  <textarea class='form-control' name='MESSAGE' rows='10'></textarea>
	  </div>
	  <div class='form-group'>
          <input type='submit' class='btn btn-primary' value='_{SEND}_'>
	  </div>
	</div>
</div>

</form>