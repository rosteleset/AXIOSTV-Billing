<div class='col-xs-12 col-md-6'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{INFO}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMPANY_NAME'>_{NAME}_:</label>
        <div class='col-sm-8 col-md-8'>
          <textarea cols='40' rows='4' id='COMPANY_NAME' name='COMPANY_NAME'
                    class='form-control'>%COMPANY_NAME%</textarea>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ADDRESS'>_{ADDRESS}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input class='form-control' id='ADDRESS' placeholder='%ADDRESS%' name='ADDRESS' value='%ADDRESS%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PHONE'>_{PHONE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input class='form-control' id='PHONE' placeholder='%PHONE%' name='PHONE' value='%PHONE%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='REPRESENTATIVE'>_{REPRESENTATIVE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input class='form-control' id='REPRESENTATIVE' placeholder='%REPRESENTATIVE%' name='REPRESENTATIVE'
                 value='%REPRESENTATIVE%'>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{OTHER}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='DEPOSIT'>_{DEPOSIT}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='DEPOSIT' placeholder='%DEPOSIT%' name='DEPOSIT' value='%DEPOSIT%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='CREDIT'>_{CREDIT}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT' value='%CREDIT%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='CREDIT_DATE'>_{DATE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input type='date' id='CREDIT_DATE' class='form-control' name='DATE' value=%CREDIT_DATE%>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='REGISTRATION'>_{REGISTRATION}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input type='date' id='REGISTRATION' class='form-control' name='DATE' value=%REGISTRATION%>
            </div>
          </div>

          <div class='form-group'>
            <div class='form-check'>
              <input id='DISABLE' class='form-check-input' name='DISABLE' value='1' %DISABLE% type='checkbox'>
              <label class='form-check-label' for='DISABLE'>_{DISABLE}_</label>
            </div>
          </div>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{BANK}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='VAT'>_{VAT}_ (%):</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='VAT' placeholder='%VAT%' name='VAT' value='%VAT%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='TAX_NUMBER'>_{TAX_NUMBER}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='TAX_NUMBER' placeholder='%TAX_NUMBER%' name='TAX_NUMBER'
                     value='%TAX_NUMBER%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='BANK_ACCOUNT'>_{ACCOUNT}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='BANK_ACCOUNT' placeholder='%BANK_ACCOUNT%' name='BANK_ACCOUNT'
                     value='%BANK_ACCOUNT%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='BANK_NAME'>_{BANK}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='BANK_NAME' placeholder='%BANK_NAME%' name='BANK_NAME'
                     value='%BANK_NAME%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COR_BANK_ACCOUNT'>_{COR_BANK_ACCOUNT}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='COR_BANK_ACCOUNT' placeholder='%COR_BANK_ACCOUNT%'
                     name='COR_BANK_ACCOUNT'
                     value='%COR_BANK_ACCOUNT%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='BANK_BIC'>_{BANK_BIC}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='BANK_BIC' placeholder='%BANK_BIC%' name='BANK_BIC'
                     value='%BANK_BIC%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='EDRPOU'>_{EDRPOU}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='EDRPOU' placeholder='%EDRPOU%' name='EDRPOU'
                     value='%EDRPOU%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='CONTRACT_ID'>_{CONTRACT_ID}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='CONTRACT_ID' placeholder='%CONTRACT_ID%' name='CONTRACT_ID'
                     value='%CONTRACT_ID%'>
            </div>
          </div>
        </div>
      </div>


      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{EXTRA_ABBR}_. _{FIELDS}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          %INFO_FIELDS%
        </div>
      </div>
    </div>
  </div>
</div>