<form action='%URL%' method='get' target='_blank'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='merchant_id' value='%MERCHANT_ID%'/>
    <input type='hidden' name='merchant_user_id' value='%UID%'/>
    <input type='hidden' name='service_id' value='%SERVICE_ID%'/>
    <input type='hidden' name='transaction_param' value='%TRANSACTION_ID%'/>
    <input type='hidden' name='amount' value='%AMOUNT%'/>

    <div class='card-header with-border text-center'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group text-center'>
        <img src='/styles/default/img/paysys_logo/click-logo.png'
             style='width: auto; max-height: 200px;'
             alt='click'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{PAY_SYSTEM}_</b>
          <div class='float-right'>Click</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>$FORM{OPERATION_ID}</div>
        </li>
        <li class='list-group-item'>
          <b>_{SUM}_</b>
          <div class='float-right'>$FORM{SUM}</div>
        </li>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>$FORM{SUM}</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>

    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit value=_{PAY}_>
    </div>
  </div>
</form>
