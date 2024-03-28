<form action='$SELF_URL' class='form-horizontal'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<input type=hidden name='TI_ID' value='%TI_ID%'>

  <div class='card card-primary card-outline card-form'>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label' for='DAYS'>_{DAY}_:</label>
        <div class='col-md-9'>
          %SEL_DAYS%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='TI_BEGIN'>_{BEGIN}_:</label>
        <div class='col-md-9'>
          <input id='TI_BEGIN' name='TI_BEGIN' value='%TI_BEGIN%' placeholder='%TI_BEGIN%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='TI_END'>_{END}_:</label>
        <div class='col-md-9'>
          <input id='TI_END' name='TI_END' value='%TI_END%' placeholder='%TI_END%' class='form-control' type='text'>
        </div>
      </div>
    </div>


      <div class='card-footer'>
        <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
      </div>
  </div>
</form>

