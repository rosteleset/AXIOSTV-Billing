<form id='liqpay_form' method='post' action='https://www.liqpay.ua/api/checkout' accept-charset='utf-8'>
  <div class='card card-primary card-outline'>
    %BODY%
    <input type='hidden' name='signature' value='%SIGN%'/>
    <input type='hidden' name='language' value='ru'/>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body pt-0'>
      <div class='text-center m-1'>
        <img src='/styles/default/img/paysys_logo/liqpay-logo.png'
             style='max-width: 300px; max-height: 200px;'
             alt='LiqPay'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>$FORM{DESCRIBE}</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>$FORM{OPERATION_ID}</div>
        </li>
        <li class='list-group-item'>
          <b>_{BALANCE_RECHARCHE_SUM}_</b>
          <div class='float-right'>%SUM%</div>
        </li>
        <li class='list-group-item'>
          <b>_{COMMISSION_LIQPAY}_</b>
          <div class='float-right'>%COMMISSION_SUM%</div>
        </li>
        <li class='list-group-item'>
          <b>_{TOTAL}_ _{SUM}_</b>
          <div class='float-right'>%TOTAL_SUM%</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </div>
</form>
