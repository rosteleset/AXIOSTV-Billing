<form action=$SELF_URL method=post>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline box-form form-horizontal container-md'>

    <div class='card-header with-border text-center'><h4 class='card-title'>_{TYPE}_ _{BONUS}_</h4></div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{SUM}_</label>
        <div class='col-md-9'>
          <input type='number' name='AMOUNT' value='%AMOUNT%' class='form-control'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <button class='btn btn-primary' type='submit' name="%ACTION%" value="%ACTION_LANG%">%ACTION_LANG%</button>
    </div>

  </div>

</form>