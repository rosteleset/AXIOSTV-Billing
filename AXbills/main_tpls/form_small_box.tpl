<div class='modal fade' id='changeCreditModal' data-open='%OPEN_CREDIT_MODAL%'>
  <div class='modal-dialog modal-sm'>
    <form action='$SELF_URL' class='pswd-confirm' id='changeCreditForm'>
      <div class='modal-content'>
        <div class='modal-header'>
          <h6 class='modal-title text-center'>_{SET_CREDIT}_</h6>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
              aria-hidden='true'>×</span></button>
        </div>
        <div class='modal-body' style='padding: 30px;'>
          <input type='hidden' name='index' value='10'>
          <input type='hidden' name='sid' value='$sid'>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4' FOR='CREDIT_SUM'>_{CREDIT_SUM}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input type='text' id='CREDIT_SUM' name='CREDIT_SUM' value='%CREDIT_SUM%' class='form-control' readonly>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4' for='CREDIT_CHG_PRICE'>_{CREDIT_PRICE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input type='text' name='CREDIT_CHG_PRICE' id='CREDIT_CHG_PRICE' value='%CREDIT_CHG_PRICE%' class='form-control' readonly>
            </div>
          </div>

          <div class='form-group row'>
            <div class='col-sm-12 col-md-12 custom-control custom-checkbox'>
              <input required='required' class='custom-control-input' type='checkbox' id='change_credit' name='change_credit' value='%CREDIT_SUM%'>
              <label for='change_credit' class='col-sm-4 col-md-4 custom-control-label'>_{ACCEPT}_</label>
            </div>
          </div>
        </div>

        <div class='modal-footer'>
          <input type='submit' class='btn btn-primary' value='_{SET}_' name='set'>
        </div>
      </div>
    </form>
  </div>
</div>
<!-- /.modal -->

<div class='callout callout-dan ger'>
  <h5>_{STATUS}_: <b>%INTERNET_STATUS%</b></h5>
    <h6>_{SET}_ _{CREDIT}_?</h6>
    <label>
        <input type='checkbox'> _{CONFIRM}_
    </label>
    <button type='submit' class='btn btn-primary' name='hold_up_window' data-toggle='modal' data-target='#changeCreditModal'>_{YES}_!</button>
</div>
