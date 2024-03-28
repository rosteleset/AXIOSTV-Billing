<div class='card card-primary card-outline'>
  <form method='POST'>
    <input type='hidden' name='index' value='%index%'>
    <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
    <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'>
    <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'>
    <input type='hidden' name='SUM' value='%SUM%'>
    <input type='hidden' name='TOTAL_SUM' value='%TOTAL_SUM%'>
    <input type='hidden' name='SUBSCRIBE_FORM' value='1'>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>

    <div class='card-body pt-0'>
      <div class='text-center'>
        <img style='width: auto; max-height: 200px;'
             src='/styles/default/img/paysys_logo/fondy-logo.png'
             alt='Fondy'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{CREATE_SUBSCRIBE}_ Fondy</b>
          <div class='float-right'>
            <input type='checkbox'
                   data-sidebarskin='toggle'
                   data-return='1'
                   name='REQUIRED_RECTOKEN'
                   value='Y'/>
          </div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </form>
</div>
