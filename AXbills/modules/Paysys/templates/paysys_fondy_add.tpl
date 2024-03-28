<form action=%FORM_ACTION% method='POST' name='tocheckout'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='server_callback_url' value=%SERVER_CALLBACK_URL%>
    <input type='hidden' name='order_id' value='%ORDER_ID%'>
    <input type='hidden' name='order_desc' value='%ORDER_DESC%'>
    <input type='hidden' name='currency' value='%CURRENCY%'>
    <input type='hidden' name='amount' value='%AMOUNT%'>
    <input type='hidden' name='signature' value='%SIGNATURE%'>
    <input type='hidden' name='merchant_id' value='%MERCHANT_ID%'>
    <input type='hidden' name='merchant_data' value='%MERCHANT_DATA%'>
    <input type='hidden' name='required_rectoken' value='%REQUIRED_RECTOKEN%'>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>

    <div class='card-body pt-0'>
      <div class='text-center'>
        <img style='width: auto; max-height: 200px;'
             src='/styles/default/img/paysys_logo/fondy-logo.png'
             alt='Fondy'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>$FORM{DESCRIBE}</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>%ORDER_ID%</div>
        </li>
        <li class='list-group-item'>
          <b>_{BALANCE_RECHARCHE_SUM}_</b>
          <div class='float-right'>%SUM%</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </div>
</form>
