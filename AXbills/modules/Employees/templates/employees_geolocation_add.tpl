<form action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type='hidden' name='index' value='%index%'>
<input type='hidden' name='EID' value='%EID%'>

<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4>_{EMPLOYEE}_ - %A_LOGIN% : %A_FIO%</h4></div>
  <div class="card-body">
  	<div class='row'>
  		<div class='col-sm-12 col-md-12'>
  		%GEOLOCATION_TREE%
  		</div>
  	</div>
  	<div class='checkbox'>
  	    <label>
  	      <input type='checkbox' name='CLEAR' value=1> _{CLEAR_GEO}_
  	    </label>
  	</div>
  	</div>
  <div class="card-footer">
  	<input type='submit' class='btn btn-primary' name='BUTTON' value='%BTN_NAME%'>
  </div>
</div>
</form>