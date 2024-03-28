  <div class='col-md-6'>
    <div class='card card-primary card-outline box-big-form'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{BILL}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 control-label' for='CONTRACT_ID'>_{CONTRACT_ID}_:</label>
          <div class='col-sm-8 col-md-8'>
            <div class='input-group'>
              <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' class='form-control' type='text'/>
              <div class='input-group-append'>
                <div class='input-group-text'>
                  <i class='fa fa-exclamation'></i>
                  <input type='checkbox' name='CONTRACT_ID' data-input-disables=CONTRACT_ID value='!'>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 control-label' for='CONTRACT_DATE'>_{CONTRACT}_ _{DATE}_:</label>
          <div class='col-sm-8 col-md-8'>
            <input id='CONTRACT_DATE' name='CONTRACT_DATE'
              value='%CONTRACT_DATE%' placeholder='%CONTRACT_DATE%' class='form-control datepicker' type='text'/>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 control-label' for='COMMENTS'>_{COMMENTS}_:</label>
          <div class='col-sm-8 col-md-8'>
            <input id='COMMENTS' name='COMMENTS' value='%COMMENTS%' placeholder='%COMMENTS%'
              class='form-control' type='text'/>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 control-label' for='DEPOSIT'>_{DEPOSIT}_:</label>
          <div class='col-sm-8 col-md-8'>
            <input id='DEPOSIT' name='DEPOSIT' value='%DEPOSIT%' placeholder='%DEPOSIT%'
              class='form-control' type='text'/>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 control-label' for='BILL_ID'>_{BILL}_:</label>
          <div class='col-sm-8 col-md-8'>
            <input id='BILL_ID' name='BILL_ID' value='%BILL_ID%' placeholder='%BILL_ID%'
              class='form-control' type='text'/>
          </div>
        </div>
        %CONTRACT_TYPE_FORM%
        %DOMAIN_FORM%
      </div>
    </div>
  </div>
  <div class='col-md-6'>
  <div class='card card-primary card-outline collapsed-card'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{CREDIT}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-plus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='CREDIT'>_{SUM}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%'
            class='form-control' type='text'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='CREDIT_DATE'>_{DATE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='CREDIT_DATE' name='CREDIT_DATE' value='%CREDIT_DATE%'
            placeholder='%CREDIT_DATE%' class='form-control datepicker' type='text'/>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{PAYMENTS}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='PAYMENTS'>_{DATE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input id='PAYMENTS' name='PAYMENTS' value='%PAYMENTS%' placeholder='%PAYMENTS%'
                class='form-control' type='text'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='PAYMENT_DAYS'>_{DAYS}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input id='PAYMENT_DAYS' name='PAYMENT_DAYS' value='%PAYMENT_DAYS%'
                placeholder='%PAYMENT_DAYS%' class='form-control' type='text'/>
            </div>
          </div>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{FEES}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='FEES'>_{DATE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input id='FEES' name='FEES' value='%FEES%' placeholder='%FEES%' class='form-control'
                type='text'/>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='FEES_DAYS'>_{DAYS}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input id='FEES_DAYS' name='FEES_DAYS' value='%FEES_DAYS%' placeholder='%FEES_DAYS%'
                  class='form-control' type='text'/>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>