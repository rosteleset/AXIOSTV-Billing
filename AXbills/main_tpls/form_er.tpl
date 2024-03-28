<form class='form-horizontal' action='$SELF_URL' METHOD='POST' role='form'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='chg' value='$FORM{chg}'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{EXCHANGE_RATE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='ER_NAME' class='col-md-4 col-form-label text-md-right'>_{MONEY}_:</label>
        <div class='col-md-8'>
          <input class='form-control' id='ER_NAME' placeholder='ER_NAME' name='ER_NAME' value='%ER_NAME%'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='ER_SHORT_NAME' class='col-md-4 col-form-label text-md-right'>_{SHORT_NAME}_:</label>
        <div class='col-md-8'>
          <input class='form-control' id='ER_SHORT_NAME' placeholder='ER_SHORT_NAME' name='ER_SHORT_NAME'
                 value='%ER_SHORT_NAME%'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='ISO' class='col-md-4 col-form-label text-md-right'>ISO:</label>
        <div class='col-md-8'>
          <input class='form-control' id='ISO' placeholder='ISO' name='ISO' value='%ISO%'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='ER_RATE' class='col-md-4 col-form-label text-md-right'>_{EXCHANGE_RATE}_:</label>
        <div class='col-md-8'>
          <input class='form-control' id='ER_RATE' placeholder='ER_RATE' name='ER_RATE' value='%ER_RATE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{CHANGED}_:</label>
        <div class='col-md-8'>
          <label class='col-sm-3 control-label'>%CHANGED%</label>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</form>
