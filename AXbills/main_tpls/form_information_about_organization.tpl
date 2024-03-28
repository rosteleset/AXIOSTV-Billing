<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='OLD_PARAM' value='%OLD_PARAM%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{ORGANIZATION_INFO}_</h3>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{TAGS}_</label>
        <div class='col-md-8'>
          %TAGS_PANEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>%LABEL% _{VALUE}_</label>
        <div class='col-md-8'>
          %VALUE_INPUT%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BUTTON_NAME%' value='%ACTION%'>
    </div>
  </div>
</form>
