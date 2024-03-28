<form action='$SELF_URL' method='post' name='account_add'>
  <input type=hidden name=index value=$index>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='sid' value='$FORM{sid}'>
  <input type=hidden name='UNINVOICED' value='1'>
  <div class='container-fluid'>
    <div class='card card-primary card-outline'>
      <div class='card-header'><h4 class='card-title'>_{PAYMENTS}_</h4></div>
      <div class='card-body'>
        <div class='form-group col-xs-12' align='center'>
          %PAYMENTS_LIST%
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label text-center'>_{SUM}_:</label>
          <div class='col-md-9'>
            <input type='text' name='SUM' value='%SUM%' size='8' class='form-control'/>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label text-center'>_{INVOICE}_:</label>
          <label class='col-md-9'>%INVOICE_SEL%</label>
        </div>
        <div class='form-group'>
          <canvas class='col-xs-12' height='2'></canvas>
        </div>
      </div>
      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' name='apply' value='_{APPLY}_'>
      </div>
    </div>
  </div>
</form>
