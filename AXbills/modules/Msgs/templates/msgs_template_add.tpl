<div class='card card-primary card-outline box-form'>
<div class='card-body'>

<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data' name='add_message' id='add_message' class='form-horizontal'>
    <legend>_{TEMPLATES}_</legend>
<fieldset>

<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='add_form' value='1'/>
<input type='hidden' name='ID' value='$FORM{chg}'/>

<div class='form-group'>
    <label class='control-label col-md-3' for='NAME'>_{NAME}_</label>
  <div class='col-md-9'>
 	  <input type='text' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' required>
 	</div>
</div>


<div class='form-group'>
    <label class='control-label col-sm-3' for='TPL'>_{TEXT}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' id='TPL' name='TPL' rows='3' class='form-control' >%TPL%</textarea>
    </div>
</div>

	 	 
<div class='form-group'>
    <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3' class='form-control' >%COMMENTS%</textarea>
    </div>
</div>

<div class='form-group'>
    <label class='control-label col-sm-3' for='FILE_UPLOAD_1'>_{ATTACHMENT}_ 1</label>
	  <div class='col-sm-6'>
  	  <input type='file' name='FILE_UPLOAD_1' ID='FILE_UPLOAD_1' value='%FILE_UPLOAD%' placeholder='%FILE_UPLOAD%' class='form-control' >
	  </div>
</div>

<div class='col-sm-offset-2 col-sm-8'>
 	<input type=submit name='%ACTION%' class='btn btn-primary' value='%LNG_ACTION%' id='go' title='Ctrl+C'/>
</div>

</fieldset>

</FORM>

</div>
</div>
