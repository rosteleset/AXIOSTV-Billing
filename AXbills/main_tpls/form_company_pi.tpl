<div>
  <input type='hidden' name='COMPANY_ID' value='%COMPANY_ID%'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='FIO_REQUIRE' id='FIO_REQUIRE' value='$FORM{FIO_REQUIRE}'>

  <div class='%FORM_ATTR%'>
    %MAIN_USER_TPL%
  </div>
  <div id='form_2' class='card for_sort card-primary card-outline %FORM_ATTR%'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{INFO}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-3 col-md-2 text-right control-label' for='NAME'>_{NAME}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input id='NAME' class='form-control' name='NAME' value='%NAME%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-3 col-md-2 text-right control-label' for='REPRESENTATIVE' >_{REPRESENTATIVE}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='REPRESENTATIVE' name='REPRESENTATIVE' value='%REPRESENTATIVE%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-3 col-md-2 text-right control-label' for='PHONE'>_{PHONE}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='PHONE' name='PHONE' value='%PHONE%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label for='TAX_NUMBER' class='col-sm-3 col-md-2 text-right control-label'>_{TAX_NUMBER}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='TAX_NUMBER' placeholder='%TAX_NUMBER%' name='TAX_NUMBER' value='%TAX_NUMBER%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label for='EDRPOU' class='col-sm-3 col-md-2 text-right control-label'>_{EDRPOU}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='EDRPOU' placeholder='%EDRPOU%' name='EDRPOU' value='%EDRPOU%'>
          </div>
        </div>
      </div>

    </div>

    %ADDRESS_TPL%
    %DOCS_TEMPLATE%

    <!-- Other panel  -->
    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
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

    <div class='card-footer'>
      <input type=submit class='btn btn-primary double_click_check' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</div>
