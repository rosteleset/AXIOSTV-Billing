<form action=%PAY_URL% method='POST'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='key' value=%KEY%>
    <input type='hidden' name='payment' value=%PAYMENT%>
    <input type='hidden' name='order' value=%ORDER_ID%>
    <input type='hidden' name='data' value=%PRODUCT_DATA%>
    <input type='hidden' name='ext1' value=%UID%>
    <input type='hidden' name='url' value=%URL_OK%>
    <input type='hidden' name='sign' value=%SIGNATURE%>
    <input type='hidden' name='commission' value=%COMMISSION%>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>

    <div class='card-body pt-0'>
      <div class='text-center'>
        <img src='/styles/default/img/paysys_logo/platon-logo.png'
             style='max-width: 300px; max-height: 200px;'
             alt='Platon'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>$FORM{OPERATION_ID}</div>
        </li>
        <li class='list-group-item'>
          <b>_{SUM}_</b>
          <div class='float-right'>%SUM%</div>
        </li>
        <li class='list-group-item'>
          <b>_{SERVICE_FEE}_</b>
          <div class='float-right'>%SERVICE%</div>
        </li>
        <li class='list-group-item'>
          <b>_{TOTAL}_</b>
          <div class='float-right'>%TOTAL%</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </div>
</form>
