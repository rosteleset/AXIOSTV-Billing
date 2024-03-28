<form action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type=hidden name=qindex value=$index>
<input type=hidden name=sid value=$sid>
<input type=hidden name=VOD value=$FORM{VOD}>
<fieldset>
	 <legend>Enter PIN For media access</legend>
	<div class='form-group'>
  <label class='control-label col-md-6' for='PIN'>_{NUM}_:</label>
  <div class='col-md-3'>
    <input  name='PIN'  class='form-control' type='password'> <input type=submit name=ACCESS value=_{ENTER}_>
  </div>
 </div>



	</fieldset>
<!--
<table width=400 class=form>
<tr><td>Enter PIN For media access</td></tr>
<tr><td><input type=password name=PIN> <input type=submit name=ACCESS value=_{ENTER}_></td></tr>
</table>
-->
</form>
