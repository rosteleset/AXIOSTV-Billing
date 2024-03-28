<FORM action='$SELF_URL' METHOD='POST'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='SURVEY_ID' value='$FORM{SURVEY_ID}'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{QUESTIONS}_</h4>
    </div>
    <div class='card-body form form-horizontal'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='NUM'>_{NUM}_:</label>
        <div class='col-md-9'>
          <input type='text' id='NUM' name='NUM' value='%NUM%' class='form-control'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='QUESTION'>_{QUESTION}_:</label>
        <div class='col-md-9'>
          <input type='text' id='QUESTION' name='QUESTION' value='%QUESTION%' size='40' class='form-control'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='PARAMS'>_{PARAMS}_ (;):</label>
        <div class='col-md-9'>
          <textarea id='PARAMS' name='PARAMS' rows='6' cols='45' class='form-control'>%PARAMS%</textarea>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <textarea name='COMMENTS' id='COMMENTS' rows='6' cols='45' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
      <div class='from-group row'>
        <label class='col-md-6' for='USER_COMMENTS'>_{USER}_ _{COMMENTS}_:</label>
        <div class='col-md-1'>
          <input type='checkbox' class='form-check-input' id='USER_COMMENTS' name='USER_COMMENTS' %USER_COMMENTS% value='1'>
        </div>
        <label class='col-md-4' for='FILL_DEFAULT'>_{DEFAULT}_:</label>
        <div class='col-md-1'>
          <input type='checkbox' class='form-check-input' id='FILL_DEFAULT' name='FILL_DEFAULT' %FILL_DEFAULT% value='1'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>
