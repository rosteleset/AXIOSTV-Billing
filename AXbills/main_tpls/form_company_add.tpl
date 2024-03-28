<form action='$SELF_URL' METHOD='POST' name='company' class='form-horizontal' enctype='multipart/form-data'>
  <input type=hidden name='index' value='13'>
  <input type=hidden name='ID' value='%ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'><h3 class='card-title'>_{USER_ACCOUNT}_: _{COMPANY}_</h3></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='NAME' class='control-label col-md-3 required'>_{NAME}_:</label>
        <div class='input-group col-md-9'>
          <input class='form-control' id='NAME' required placeholder='%NAME%' name='NAME' value='%NAME%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='BILL_ID'>_{BILL}_:</label>
        <div class='form-check col-md-4'>
          %BILL_ID%
        </div>
      </div>

      <div class='form-group row'>
        <label for='CREDIT' class='control-label col-md-3'>_{CREDIT}_:</label>
        <div class='input-group col-md-4'>
          <input type="number" step="0.01" class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT' value='%CREDIT%'>
        </div>
        <label for='CREDIT_DATE' class='control-label col-md-1'>_{DATE}_:</label>
        <div class='input-group col-md-4'>
          <input class='datepicker form-control' id='CREDIT_DATE' placeholder='%CREDIT_DATE%' name='CREDIT_DATE'
                        value='%CREDIT_DATE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-right col-4 col-md-3' for='DISABLE'>_{DISABLE}_</label>
        <div class = 'col-md-1'>
          <input id='DISABLE' name='DISABLE' value='1' %DISABLE% type='checkbox'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='REGISTRATION' class='control-label col-md-3'>_{REGISTRATION}_:</label>
        <div class='input-group col-md-9'>
          <input class='form-control' id='REGISTRATION' placeholder='%REGISTRATION%' name='REGISTRATION'
                 value='%REGISTRATION%'>
        </div>
      </div>
    </div>
    <div class='card card-outline card-primary'>
      <div class='card-header'>
        <h3 class='card-title'>_{COMPANY}_</h3>
      </div>
      <div class='card-body'>
        <div class='form-group row'>
          <label for='TAX_NUMBER' class='control-label col-md-3'>_{TAX_NUMBER}_:</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='TAX_NUMBER' placeholder='%TAX_NUMBER%' name='TAX_NUMBER' value='%TAX_NUMBER%'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='BANK_ACCOUNT' class='control-label col-md-3'>_{ACCOUNT}_:</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='BANK_ACCOUNT' placeholder='%BANK_ACCOUNT%' name='BANK_ACCOUNT'
                   value='%BANK_ACCOUNT%'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='BANK_NAME' class='control-label col-md-3'>_{BANK}_:</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='BANK_NAME' placeholder='%BANK_NAME%' name='BANK_NAME' value='%BANK_NAME%'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='COR_BANK_ACCOUNT' class='control-label col-md-3'>_{COR_BANK_ACCOUNT}_:</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='COR_BANK_ACCOUNT' placeholder='%COR_BANK_ACCOUNT%' name='COR_BANK_ACCOUNT'
                   value='%COR_BANK_ACCOUNT%'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='BANK_BIC' class='control-label col-md-3'>_{BANK_BIC}_:</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='BANK_BIC' placeholder='%BANK_BIC%' name='BANK_BIC' value='%BANK_BIC%'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='EDRPOU' class='control-label col-md-3'>_{EDRPOU}_:</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='EDRPOU' placeholder='%EDRPOU%' name='EDRPOU' value='%EDRPOU%'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='VAT' class='control-label col-md-3'>_{VAT}_ (%):</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='VAT' placeholder='%VAT%' name='VAT' value='%VAT%'>
          </div>
        </div>
      </div>

      %EXDATA%

    </div>
    <div class='card card-outline card-primary'>
      <div class='card-header'>
        <h3 class='card-title'>_{INFO}_</h3>
      </div>
      <div class='card-body'>
        <div class='form-group row'>
          <label for='REPRESENTATIVE' class='control-label col-md-3'>_{REPRESENTATIVE}_:</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='REPRESENTATIVE' placeholder='%REPRESENTATIVE%' name='REPRESENTATIVE'
                   value='%REPRESENTATIVE%'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='PHONE' class='control-label col-md-3'>_{PHONE}_:</label>
          <div class='input-group col-md-9'>
            <input class='form-control' id='PHONE' placeholder='%PHONE%' name='PHONE' value='%PHONE%'>
          </div>
        </div>
      </div>
    </div>

    %ADDRESS_TPL%
    %DOCS_TEMPLATE%

    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
      <div class='card-header'>
        <h3 class='card-title'>_{EXTRA_ABBR}_. _{FIELDS}_</h3>
        <div class='card-tools'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        %INFO_FIELDS%
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>

  </div>
</form>

