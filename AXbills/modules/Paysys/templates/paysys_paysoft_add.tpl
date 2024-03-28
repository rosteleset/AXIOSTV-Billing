<form id='Paysoft' name='Paysoft' method='POST' action='%ACTION_URL%'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='LMI_MERCHANT_ID' value='%LMI_MERCHANT_ID%'>
    <input type='hidden' name='LMI_RESULT_URL' value='%PAYSYS_LMI_RESULT_URL%'>
    <input type='hidden' name='LMI_SUCCESS_URL' value='%LMI_SUCCESS_URL%'>
    <input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
    <input type='hidden' name='LMI_FAIL_URL' value='%LMI_FAIL_URL%'>
    <input type='hidden' name='LMI_FAIL_METHOD' value='2'>
    <input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
    <input type='hidden' name='at' value='%AT%'>
    <input type='hidden' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%'>
    <input type='hidden' name='LMI_PAYMENT_SYSTEM' value='%LMI_PAYMENT_SYSTEM%'>
    <input type='hidden' name='UID' value='%UID%'>
    <input type='hidden' name='sid' value='%SID%'>
    <input type='hidden' name='IP' value='%IP%'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>
    %TEST_MODE%

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body pt-0'>
      <div class='text-center'>
        <img src='/styles/default/img/paysys_logo/paysoft-logo.png'
             style='width: auto; max-height: 200px;'
             alt='paysoft'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>$FORM{DESCRIBE}</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>%LMI_PAYMENT_NO%</div>
        </li>
        <li class='list-group-item'>
          <b>_{BALANCE_RECHARCHE_SUM}_</b>
          <div class='float-right'>%LMI_PAYMENT_AMOUNT%</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </div>
</form>
