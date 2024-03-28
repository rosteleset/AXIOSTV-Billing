<div class='card w-50'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{HOLD_UP}_</h4>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>

  <div class='card-body'>
    <form action='$SELF_URL' METHOD='GET' id='holdup_%ID%'>
      <input type='hidden' name='index' value='%index%'>
      <input type='hidden' name='sid' value='%sid%'>
      <input type='hidden' name='UID' value='%UID%'>
      <input type='hidden' name='ID' value='%ID%'>
      <input type='hidden' name='holdup' value='1'>

      <div class='form-group row'>
        <label class='col-md-3 control-label' FOR='FROM_DATE'>_{FROM}_:</label>

        <div class='col-md-9'>
          <input type='text' name='FROM_DATE' value='%FROM_DATE%' size='10' class='form-control datepicker'
                 id='FROM_DATE' form='holdup_%ID%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label' for='TO_DATE'>_{TO}_:</label>
        <div class='col-md-9'>
          <input type='text' name='TO_DATE' value='%TO_DATE%' size='10' class='form-control datepicker'
                 id='TO_DATE' form='holdup_%ID%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' FOR='HOLDUP_PRICE'>_{PRICE}_:</label>

        <div class='col-md-9'>
          <input type='text' name='HOLDUP_PRICE' value='%HOLDUP_PRICE%' size='10' class='form-control'
                 id='HOLDUP_PRICE' form='holdup_%ID%'>
        </div>
      </div>

      <div class='form-group row'>
        <p class='form-control-static'>%DAY_FEES%</p>
      </div>
      <div class='checkbox text-center'>
        <label class='required' for='ACCEPT_RULES'>
          <strong>_{ACCEPT}_</strong>
        </label>
        <input type='checkbox' name='ACCEPT_RULES' id='ACCEPT_RULES' value='1' required>
      </div>
    </form>
  </div>

  <div class='card-footer'>
    <input type='submit' value='_{HOLD_UP}_' name='add' form='holdup_%ID%' class='btn btn-primary'>
  </div>

</div>