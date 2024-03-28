<form action='https://easypay.ua/merchant/2_3/order ' method='post'>
  <input type='hidden' name='secret_key' value='%SECRET_KEY%'>
  <input type='hidden' name='merchant_id' value='%MERCHANT_ID%'/>
  <input type='hidden' name='order_id' value='$FORM{OPERATION_ID}'/>
  <input type='hidden' name='amount' value='$FORM{SUM}'>
  <input type='hidden' name='desc' value='$FORM{DESCRIBE}'/>
  <input type='hidden' name='url_success' value='%URL_SUCCESS%'/>
  <input type='hidden' name='url_failed' value='%URL_FAILED%'/>
  <input type='hidden' name='url_notify' value='%URL_NOTIFY%'/>
  <input type='hidden' name='template' value='whitepage'/>
  <input type='hidden' name='expire_date' value='%EXP_DATE%'/>
  <input type='hidden' name='signature' value='%SIGN%'/>

  <div class='container-fluid'>
    <div class='card box-primary'>
      <div class='card-header with-border text-center'>Lifecell</div>
      <div class='card-body'>

        <div class='form-group'>
          <img class='col-xs-8 col-xs-offset-2'
               src='https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRNwh39id0THh1FZmSRwPbz1b0HjIoVo2uEaxmB1wFyjOdFNgo2'>
        </div>

        <div class='form-group'>
          <label class='font-weight-bold text-center col-md-6 form-control-label'>_{ORDER}_</label>
          <label class='font-weight-bold col-md-6 form-control-label'>$FORM{OPERATION_ID}</label>
        </div>

        <div class='form-group'>
          <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{BALANCE_RECHARCHE_SUM}_:</label>
          <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>$FORM{SUM}</label>
        </div>

      </div>
      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' value='_{PAY}_'>
      </div>

    </div>
  </div>
</form>