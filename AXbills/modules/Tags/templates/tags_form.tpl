<form action='$SELF_URL' method='post' class='form-horizontal'>
  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TAGS}_</h4>
    </div>
    <div class='card-body'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='$FORM{chg}'/>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' id='NAME' name='NAME' value='%NAME%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          %PRIORITY_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESPONSIBLE'>_{RESPONSIBLE}_:</label>
        <div class='col-md-8'>
          %RESPONSIBLE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COLOR'>_{COLOR}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' id='COLOR_CHECKBOX' name='COLOR_CHECKBOX' class='form-control-static'
                       data-input-disables='COLOR'/>
              </span>
            </div>
            <input type='color' class='form-control' name='COLOR' id='COLOR' value='%COLOR%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea rows=4 id='COMMENTS' name=COMMENTS class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
    </div>
  </div>
</form>