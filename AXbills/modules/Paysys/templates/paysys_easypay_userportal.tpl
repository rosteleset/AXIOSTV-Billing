<form method='post'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='MAKE_PAYMENT' value='1'/>
    <input type='hidden' name='index' value='%INDEX%'/>
    <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'/>
    <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'/>
    <input type='hidden' name='SUM' value='%SUM%'/>
    <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'/>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>

    <div class='card-body pt-0'>
      <div class='text-center'>
        <img style='width: auto; max-height: 200px;'
             src='/styles/default/img/paysys_logo/easypay-logo.png'
             alt='EasyPay'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>$FORM{DESCRIBE}</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>%OPERATION_ID%</div>
        </li>
        <li class='list-group-item'>
          <b>_{BALANCE_RECHARCHE_SUM}_</b>
          <div class='float-right'>%SUM%</div>
        </li>
        <li class='list-group-item'>
          <b>_{CREATE_REGULAR_PAYMENT}_</b>
          <div class='float-right'>%CREATE_REGULAR_PAYMENT%</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </div>
</form>
