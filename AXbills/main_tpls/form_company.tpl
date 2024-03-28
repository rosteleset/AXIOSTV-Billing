<script TYPE='text/javascript'>
  'use strict';

  function add_comments() {
    console.log(document.company_profile);

    const status_label = document.getElementById('DISABLE_LABEL');
    if (document.company_profile.DISABLE.checked) {
      document.company_profile.DISABLE.checked = false;
      document.company_profile.DISABLE.checked = true;
      status_label.innerHTML = '_{DISABLE}_';
    } else {
      status_label.innerHTML = '_{ACTIV}_';
    }
  }

  jQuery(function () {
    if (jQuery('#CUSTOM_DISABLE_FORM').length) {
      jQuery('#DISABLE_FORM').remove();
    }

    jQuery('input#DISABLE').on('click', add_comments);
  });

</script>

<!-- <form action='$SELF_URL' method='post' id='company_main' name='company_main' role='form'> -->
<div>
  <div id='form_1' class='card card-primary card-outline container-md for_sort pr-0 pl-0'> <!-- XXX card-big-form? -->
    <div class='card-header with-border'>
      <h4 class='card-title'>_{USER_ACCOUNT}_: _{COMPANY}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      %EXDATA%

      <div class='form-group row'>
        <label class='col-4 col-md-2 col-form-label text-right mb-3 mb-md-0' for='CREDIT'>_{CREDIT}_:</label>
        <div class='col-8 col-md-4 mb-3 mb-md-0'>
          <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%' class='form-control r-0-9'
                 type='number' step='0.01' min='0'
                 data-tooltip='<h6>_{SUM}_:  %CREDIT%</h6><h6>_{DATE}_: %DATE_CREDIT%</h6>'
                 data-tooltip-position='top'>
        </div>

        <label class='col-4 col-md-2 col-form-label text-right' for='CREDIT_DATE'>_{TO}_:</label>
        <div class='col-8 col-md-4'>
          <input id='CREDIT_DATE' type='text' name='CREDIT_DATE' value='%CREDIT_DATE%'
                 class='datepicker form-control d-0-9'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='BANK_ACCOUNT' class='col-sm-3 col-md-2 text-right control-label'>_{ACCOUNT}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='BANK_ACCOUNT' placeholder='%BANK_ACCOUNT%' name='BANK_ACCOUNT'
                 value='%BANK_ACCOUNT%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label for='BANK_NAME' class='col-sm-3 col-md-2 text-right control-label'>_{BANK}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='BANK_NAME' placeholder='%BANK_NAME%' name='BANK_NAME' value='%BANK_NAME%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label for='COR_BANK_ACCOUNT' class='col-sm-3 col-md-2 text-right control-label'>_{COR_BANK_ACCOUNT}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='COR_BANK_ACCOUNT' placeholder='%COR_BANK_ACCOUNT%' name='COR_BANK_ACCOUNT'
                 value='%COR_BANK_ACCOUNT%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label for='BANK_BIC' class='col-sm-3 col-md-2 text-right control-label'>_{BANK_BIC}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='BANK_BIC' placeholder='%BANK_BIC%' name='BANK_BIC' value='%BANK_BIC%'>
          </div>
        </div>
      </div>
    </div>

    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{EXTRA}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>

      <div class='card-body'>
        <div class='form-group row'>
          <label class='col-md-2 col-sm-2 col-form-label' for='BILL'>_{BILL}_</label>
          <div class='col-md-4 col-sm-10'>
            <div class='input-group'>
              <input type=text name='BILL' value='%BILL_ID%' ID='BILL' class='form-control' readonly>
              <div class='input-group-append'>
                %BILL_CORRECTION%
              </div>
            </div>
          </div>

          <label class='col-md-2 col-sm-2 col-form-label' for='REG'>_{REGISTRATION}_</label>
          <div class='col-md-4 col-sm-10'>
            <input type='text' name='REG' value='%REGISTRATION%' ID='REG' class='form-control' readonly>
          </div>
        </div>

        <div class='form-group row'>
          <label for='VAT' class='col-sm-3 col-md-2 text-right control-label'>_{VAT}_ (%):</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <input class='form-control' id='VAT' placeholder='%VAT%' name='VAT' value='%VAT%'>
            </div>
          </div>
        </div>

      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary double_click_check' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</div>
<!-- </form> -->