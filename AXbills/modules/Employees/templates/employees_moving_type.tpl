<form action='$SELF_URL' METHOD=POST>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title table-caption'>_{ADD}_ _{TYPE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' placeholder='_{TYPE_IN_MOVING_TYPE}_'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TYPE}_ _{SPENDING}_:</label>
        <div class='col-md-8'>
          %SPENDING_TYPE_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TYPE}_ _{COMING}_:</label>
        <div class='col-md-8'>
          %COMING_TYPE_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
    </div>
  </div>
</form>