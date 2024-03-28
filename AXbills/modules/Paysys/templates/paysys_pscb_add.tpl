<form action='https://oos.pscb.ru/pay' method='post'>

  <input type='hidden' name='marketPlace' value='%MARKET_PLACE%'>
  <input type='hidden' name='message' value='%MESSAGE%'>
  <input type='hidden' name='signature' value='%SIGNATURE%'>


  <div class='card box-primary '>
    <div class='card-header with-border'><h4>_{BALANCE_RECHARCHE}_</h4></div>

    <div class='card-body'>
      <div class='form-group'>
        <label class='col-md-6 control-label text-right'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
      </div>

      <div class='form-group'>
        <label class='col-md-6 control-label text-right'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>PSCB</label>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-6 text-right'>_{SUM}_:</label>
        <label class='control-label col-md-6'> $FORM{SUM} </label>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit value=_{PAY}_>
    </div>
  </div>

</form>