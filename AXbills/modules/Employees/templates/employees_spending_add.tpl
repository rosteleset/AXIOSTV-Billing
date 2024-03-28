<form action='$SELF_URL' METHOD=POST>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title table-caption'>_{SPENDING}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{SUM}_:</label>
        <div class='col-md-8'>
          <input type='number' step='0.01' class='form-control' name='AMOUNT' value='%AMOUNT%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TO_USER}_:</label>
        <div class='col-md-8'>
          %ADMIN_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{SPENDING}_ _{TYPE}_:</label>
        <div class='col-md-8'>
          %SPENDING_TYPE_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{CASHBOX}_:</label>
        <div class='col-md-8'>
          %CASHBOX_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DATE}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control datepicker' name='DATE' value='%DATE%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
    </div>
  </div>

</form>