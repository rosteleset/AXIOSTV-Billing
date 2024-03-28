<form action=$SELF_URL method=post class='pswd-confirm'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='RECIPIENT' value='%RECIPIENT%'>
  <input type='hidden' name='SUM' value='%SUM%'>
  <input type='hidden' name='UID' value='%UID%'>

  <div class='card box-primary center-block'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{MONEY_TRANSFER}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-6 text-right'>UID:</label>
        <label class='col-md-6'>
          %RECIPIENT%
        </label>
      </div>
      <div class='form-group row'>
        <label class='col-md-6 text-right'>_{FIO}_:</label>
        <label class='col-md-6'>
          %FIO%
        </label>
      </div>
      <div class='form-group row'>
        <label class='col-md-6 text-right'>_{SUM}_:</label>
        <label class='col-md-6'>
          %SUM%
        </label>
      </div>
      <div class='form-group row'>
        <label class='col-md-6 text-danger text-right'>_{COMMISSION}_:</label>
        <label class='col-md-6 text-danger'>%COMMISSION%</label>
      </div>
      <div class='form-group row'>
        <label class='col-md-6 text-right' for='ACCEPT'>_{ACCEPT}_:</label>
        <div class='col-md-6'>
          <div class='form-check'>
          <input class='form-check-input' type='checkbox' id='ACCEPT' name=ACCEPT value=1>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer '>
      <input class='btn btn-primary' type='submit' name='transfer' value='_{SEND}_'/>
    </div>
  </div>
</form>
 