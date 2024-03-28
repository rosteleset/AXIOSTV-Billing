<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'>
    <h4 class='card-title'>PaySoft</h4>
  </div>
  <div class='card-body'>

    <form name='PAYSOFT_CHOOSE' id='form_PAYSOFT_CHOOSE' method='POST' class='form form-horizontal'>
      <input type='hidden' name='index' value='%index%'/>
      <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'/>
      <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'/>
      <input type='hidden' name='SUM' value='%SUM%'/>
      <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PAYMENT_METHOD'>_{SELECT_PAYMENT_METHOD}_</label>
        <div class='col-md-9'>
          %SELECT%
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_PAYSOFT_CHOOSE' class='btn btn-primary' name='SELECTED' value='_{PAY}_'>
  </div>
</div>