<form action='$SELF_URL' METHOD='POST' id='form_paid' class='form-horizontal'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='OP_SID' value='%OP_SID%'>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='ID' value='$FORM{chg}'>
  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ONETIME_ACCRUALS}_</h4>
    </div>

    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{TYPE}_</label>
        <div class='col-md-9 input-group'>
          %TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{ACCOUNT}_</label>
        <div class='col-md-9'>
          %MACCOUNT_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{DATE}_</label>
        <div class='col-md-9'>
          %DATE_LIST%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{SUM}_</label>
        <div class='col-md-9 input-group'>
          <input class='form-control' type='number' step='0.01' name='SUM' value='%SUM%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{DESCRIBE}_</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='DESCRIBE' value='%DESCRIBE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>EXT ID</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='EXT_ID' value='%EXT_ID%'>
        </div>
      </div>

      <div class='form-group row'>
        <div class='col-md-6 form-check'>
          <label class='col-md-6 control-label'>_{CLOSED}_</label>
          <input class='col-md-2 form-check-input' type='checkbox' name='STATUS' value='1' %STATUS%>
        </div>
      </div>

      <div class='form-group row'>
        <div class='col-md-6 form-check'>
          <label class='col-md-6 control-label'>_{PAIDS}_</label>
          <input class='col-md-2 form-check-input' type='checkbox' name='PAIDS' value='1' %PAIDS%>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type=submit name=%ACTION% value='%ACTION_LNG%' id='submitbutton' class='btn btn-primary'>
    </div>
  </div>
</form>

<script>
    jQuery('#form_paid').on('submit', function(){
        renameAndDisable('submitbutton', '_{IN_PROGRESS}_...' );
    });
</script>
