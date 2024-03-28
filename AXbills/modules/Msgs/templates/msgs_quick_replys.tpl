<form method='POST' action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{MSGS_TAGS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='REPLY'>_{TAGS}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' id='REPLY' name='REPLY' value='%REPLY%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{MSGS_TAGS_TYPES}_:</label>
        <div class='col-md-8'>
          %QUICK_REPLYS_CATEGORY%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COLOR'>_{TAGS}_:</label>
        <div class='col-md-8'>
          <input type='color' class='form-control' name='COLOR' id='COLOR' value='%COLOR%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENT'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <textarea class='form-control col-md-12' rows='2' name='COMMENT' id='COMMENT'>%COMMENT%</textarea>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <div class='col-md-12'>
        <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
      </div>
    </div>
  </div>
</form>