<form action='$SELF_URL' method='post' class='form form-horizontal'>

  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline container-md'>

    <div class='card-header with-border'><h4 class='card-title table-caption'>_{VACATIONS}_</h4></div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{EMPLOYEE}_:</label>
        <div class='col-md-8'>
          %ADMIN_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DATE}_:</label>
        <div class='col-md-8'>
          %DATE_RANGE%
      </div>
    </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
    </div>

  </div>

</form>