<form action='https://www.portmone.com.ua/gateway/' method='post'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='payee_id' value='%PAYEE_ID%'/>
    <input type='hidden' name='shop_order_number' value='%SHOP_ORDER_NUMBER%'/>
    <input type='hidden' name='bill_amount' value='%BILL_AMOUNT%'/>
    <input type='hidden' name='bill_currency' value='%BILL_CURRENCY%'/>
    <input type='hidden' name='description' value='%DESCRIBE%'/>
    <input type='hidden' name='success_url' value='%URL_SUCCESS%'/>
    <input type='hidden' name='failure_url' value='%URL_FAILED%'/>
    <input type='hidden' name='attribute1' value='%UID%'/>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body pt-0'>
      <div class='text-center'>
        <img style='width: auto; max-height: 200px;'
             src='/styles/default/img/paysys_logo/portmone-logo.png'
             alt='portmone'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>%DESCRIBE%</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>%SHOP_ORDER_NUMBER%</div>
        </li>
        <li class='list-group-item'>
          <b>_{BALANCE_RECHARCHE_SUM}_</b>
          <div class='float-right'>%SUM%</div>
        </li>
        <li class='list-group-item'>
          <b>_{COMMISSION}_</b>
          <div class='float-right'>%COMMISSION%</div>
        </li>
        <li class='list-group-item'>
          <b>_{TOTAL}_ _{SUM}_</b>
          <div class='float-right'>%BILL_AMOUNT%</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </div>
</form>
