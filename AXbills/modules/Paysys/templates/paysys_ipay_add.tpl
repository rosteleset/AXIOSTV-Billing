<div class='card card-primary card-outline'>
  <form id=pay name=pay method='POST' action='https://api.ipay.ua/simple/'>
    <input type='hidden' name='good'
           value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&ipay_transaction=%IPAY_PAYMENT_NO%'>
    <input type='hidden' name='bad'
           value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&ipay_transaction=FALSE&trans_num=%IPAY_PAYMENT_NO%'>
    <input type='hidden' name='IPAY_PAYMENT_NO' value='%IPAY_PAYMENT_NO%'>
    <input type='hidden' name='UID' value='%UID%'>
    <input type='hidden' name='sid' value='%sid%'>
    <input type='hidden' name='IP' value='%IP%'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='id' value='%MERCHANT_ID%'>
    <input type='hidden' name='amount' value='%amount%'>
    <input type='hidden' name='desc' value='%desc%'>
    <input type='hidden' name='info' value='%info%'>
    <input type='hidden' name='lang' value='%lang%'>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>


    <div class='card-body pt-0'>
      <div class='text-center'>
        <img style='width: auto; max-height: 200px;'
             src='/styles/default/img/paysys_logo/ipay-logo.png'
             alt='iPay'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>$FORM{DESCRIBE}</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>%IPAY_PAYMENT_NO%</div>
        </li>
        <li class='list-group-item'>
          <b>_{SUM}_</b>
          <div class='float-right'>%SUM% %amount_with_point%</div>
        </li>
        <li class='list-group-item'>
          <b>_{HELP}_</b>
          <div class='float-right'>
            <a class='btn btn-default' href='https://www.ipay.ua/ua/faq'>_{READ_HERE}_</a>
          </div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>

      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </form>
</div>
