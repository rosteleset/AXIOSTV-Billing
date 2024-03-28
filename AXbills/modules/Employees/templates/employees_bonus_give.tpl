<form action=$SELF_URL method=post>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline box-form form-horizontal'>

    <div class='card-header with-border '><h4 class='card-title'>_{BONUS}_</h4></div>

    <div class='card-body'>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{BONUS}_</label>
        <div class='col-md-9'>
          %BONUS_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{MONTH}_</label>
        <div class='col-md-9'>
          %MONTH_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{YEAR}_</label>
        <div class='col-md-9'>
          %YEAR_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{EMPLOYEE}_</label>
        <div class='col-md-9'>
          %ADMIN_SELECT%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <button class='btn btn-primary' type='submit' name="%ACTION%" value="%ACTION_LANG%">%ACTION_LANG%</button>
    </div>

  </div>

</form>