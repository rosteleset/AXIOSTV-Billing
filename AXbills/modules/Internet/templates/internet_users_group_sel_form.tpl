<form action='$SELF_URL' class='form-horizontal' METHOD='POST'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='ID' value='$FORM{ID}'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{GROUP}_: %GROUP_NAME%</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='GROUP_SEL' class='col-md-4 col-form-label text-md-right'>_{GROUPS}_:</label>
        <div class='col-md-8'>
          %GROUP_SEL%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <button type='submit' class='btn btn-primary' name='change' value='_{CHANGE}_'>_{CHANGE}_</button>
    </div>
  </div>
</form>