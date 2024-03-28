<form action='$SELF_URL' METHOD=POST>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title table-caption'>_{MOVING_BETWEEN_CASHBOXES}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{SUM}_:</label>
        <div class='col-md-8'>
          <input type='number' step='0.01' class='form-control' name='AMOUNT' value='%AMOUNT%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{CASHBOX}_</br>_{COMING}_:</label>
        <div class='col-md-8'>
          %CASHBOX_SELECT_COMING%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{CASHBOX}_</br>_{SPENDING}_:</label>
        <div class='col-md-8'>
          %CASHBOX_SELECT_SPENDING%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{MOVING}_ _{TYPE}_:</label>
        <div class='col-md-8'>
          %MOVING_TYPE_SELECT%
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