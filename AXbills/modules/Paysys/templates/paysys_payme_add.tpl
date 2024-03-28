<form action='%URL%' method='post'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='merchant' value='%MERCHANT_ID%'/>
    <input type='hidden' name='amount' value='%AMOUNT%'/>
    <input type='hidden' name='description' value='%DESCRIBE%'/>
    <input type='hidden' name='account[%CHECK_FIELD%]' value='%USER_ID%'/>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>

    <div class='card-body pt-0'>
      <div class='form-group text-center'>
        <img src='/styles/default/img/paysys_logo/payme-logo.png'
             style='width: auto; max-height: 200px;'
             alt='payme'>
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
          <b>_{SUM}_</b>
          <div class='float-right'>$FORM{SUM}</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
</form>
