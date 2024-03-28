<form action=$SELF_URL method=post class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=chg value='$FORM{chg}'>
  <input type=hidden name=ID value='$FORM{chg}'>
  <input type=hidden name=UID value='$FORM{UID}'>
  <input type=hidden name=TP_IDS value='%TP_IDS%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='DS_ACCOUNT' value='$FORM{DS_ACCOUNT}'>
  <input type=hidden name='SUB_ID' value='%SUB_ID%'>
  <input type=hidden name='SERVICE_ID' value='$FORM{SERVICE_ID}'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SUBSCRIBES}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-label col-md-3'>_{NAME}_</label>
        <div class='col-md-9'>%SUB_ID%</div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='ID'>ID</label>
        <div class='col-md-3'>
          %ID%
        </div>

        <label class='control-label col-md-3' for='ID'>_{DATE}_</label>
        <div class='col-md-3'>
          %DATE_ADDED%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='BUNDLE_TYPE'>_{DEL}_ _{TYPE}_</label>
        <div class='col-md-9'>
          %DEL_TYPE_SEL%
        </div>
      </div>

      <div class='card-footer'>
        %BACK_BUTTON%
        <input type='submit' class='btn btn-primary' name='del_bundle' value='_{DEL}_'>
      </div>

    </div>
  </div>

</form>

