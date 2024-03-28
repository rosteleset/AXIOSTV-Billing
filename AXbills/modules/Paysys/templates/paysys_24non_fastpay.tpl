<div class='card card-primary card-outline'>
  <div class='card-header with-border text-center pb-0'>
    <h4>_{BALANCE_RECHARCHE}_</h4>
  </div>
  <div class='card-body pt-0'>
    <div class='text-center m-2'>
      <img src='/styles/default/img/paysys_logo/24_non_stop-logo.png'
           style='max-width: 320px; max-height: 200px;'
           alt='24NS'>
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
        <div class='float-right'>$FORM{SUM}</div>
      </li>
      %EXTRA_DESCRIPTIONS%
    </ul>
    <div class='axbills-form-main-buttons'>
      <a href='%LINK%' class='btn btn-primary btn-lg' role='button' id='FASTPAY'>_{PAY}_</a>
    </div>
  </div>
</div>
