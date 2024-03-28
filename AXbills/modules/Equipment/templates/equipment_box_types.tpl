<FORM action='$SELF_URL' METHOD='POST'  class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{chg}'>
<fieldset>

<div class='card card-primary card-outline box-form'>
<legend>_{BOXES}_ _{TYPE}_</legend>

<div class='card-body'>

<div class='form-group'>
  <label class='control-label col-md-3' for='MARKING'>_{MARKING}_</label>
  <div class='col-md-9'>
    <input type=text class='form-control' id='MARKING' placeholder='%MARKING%' name='MARKING' value='%MARKING%'>
  </div>
</div>

<!-- -->
<div class='form-group'>
  <label class='control-label col-md-3' for='VENDOR'>_{VENDOR}_:</label>
  <div class='col-md-9'>
    <input class='form-control' type='text' name='VENDOR' value='%VENDOR%' ID='VENDOR'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='UNITS'>_{UNITS}_:</label>
  <div class='col-md-9'>
    <input class='form-control' type='text' name='UNITS' value='%UNITS%' ID='UNITS'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='WIDTH'>_{WIDTH}_:</label>
  <div class='col-md-9'>
    <input class='form-control' type='text' name='WIDTH' value='%WIDTH%' ID='WIDTH'>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='HIEGHT'>_{HIEGHT}_:</label>
  <div class='col-md-9'>
    <input class='form-control' type='text' name='HIEGHT' value='%HIEGHT%' ID='HIEGHT'>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='LENGTH'>_{LENGTH}_:</label>
  <div class='col-md-9'>
    <input class='form-control' type='text' name='LENGTH' value='%LENGTH%' ID='LENGTH'>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='DIAMETER'>_{DIAMETER}_:</label>
  <div class='col-md-9'>
    <input class='form-control' type='text' name='DIAMETER' value='%DIAMETER%' ID='DIAMETER'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_: </label>
  <div class='col-md-9'>
    <textarea  class='form-control' name='COMMENTS' rows='6' cols='50'>%COMMENTS%</textarea>
  </div>
</div>

</div>

<div class='card-footer'>
	<input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
</div>

</div>
</fieldset>
</FORM>

