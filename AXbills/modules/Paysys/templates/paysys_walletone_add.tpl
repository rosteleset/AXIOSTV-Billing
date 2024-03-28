<form action='https://wl.walletone.com/checkout/checkout/Index' method='post'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='WMI_MERCHANT_ID' value=%WMI_MERCHANT_ID%>
    <input type='hidden' name='WMI_PAYMENT_AMOUNT' value=%WMI_PAYMENT_AMOUNT%>
    <input type='hidden' name='WMI_CURRENCY_ID' value=%WMI_CURRENCY_ID%>
    <input type='hidden' name='WMI_PAYMENT_NO' value=%WMI_PAYMENT_NO%>
    <input type='hidden' name='WMI_DESCRIPTION' value=%WMI_DESCRIPTION%>
    <input type='hidden' name='WMI_SUCCESS_URL' value=%WMI_SUCCESS_URL%>
    <input type='hidden' name='WMI_FAIL_URL' value=%WMI_FAIL_URL%>
    <input type='hidden' name='WMI_SIGNATURE' value=%WMI_SIGNATURE%>
    <input type='hidden' name='UID' value=%UID%>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body pt-0'>
      <div class='text-center'>
        <img src='/styles/default/img/paysys_logo/walletone-logo.png'
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
          <div class='float-right'>%WMI_PAYMENT_NO%</div>
        </li>
        <li class='list-group-item'>
          <b>_{BALANCE_RECHARCHE_SUM}_</b>
          <div class='float-right'>%WMI_PAYMENT_AMOUNT%</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </div>
</form>