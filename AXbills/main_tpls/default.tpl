<form action='%SELF_URL%' METHOD='POST'>
  <input type='hidden' name='index' value='%index%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{HEADER}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ID'>#:</label>
        <div class='col-md-8'>
          <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MAX_ROWS'>_{MAX_ROWS}_:</label>
        <div class='col-md-8'>
          <input id='MAX_ROWS' name='MAX_ROWS' value='%MAX_ROWS%' placeholder='%MAX_ROWS%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='SOME_SELECT' class='col-form-label text-md-right col-md-4'>_{SELECT_USER}_:</label>
        <div class='col-md-8'>
          %SOME_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{SELECT_USER}_2:</label>
        <div class='col-md-8'>
          <div class='d-flex bd-highlight'>
            <div class='flex-fill bd-highlight'>
              <div class='select'>
                <div class='input-group-append select2-append'>
                  %SOME_SELECT2%
                </div>
              </div>
            </div>
            <div class='bd-highlight'>
              <div class='input-group-append h-100'>
                <a class='btn input-group-button rounded-left-0'>
                  <span class='fa fa-list'></span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MIN_SESSION_COST'>_{MIN_SESSION_COST}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' id='MIN_SESSION_COST' name='MIN_SESSION_COST' value='%MIN_SESSION_COST%'
                   class='form-control'>
            <div class='input-group-append'>
              <a class='btn input-group-button clear_results'>
                <span class='fa fa-times'></span>
              </a>
            </div>
          </div>
        </div>
      </div>

      <!-- example of multiple inputs in one row. pay attention to spacing classes (mb-3, mb-md-0), how it works on small screens. you may want to change column sizes. another example: template form_user.tpl -->
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right mb-3 mb-md-0' for='CREDIT'>_{CREDIT}_</label>
        <div class='col-md-2 mb-3 mb-md-0'>
          <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%' class='form-control r-0-9'
                 type='number' step='0.01' min='0'> <!-- r-0-9: if admin's Customers>Credit (0-9) is disabled, make this input readonly. look at _make_perm_clases. -->

        </div>

        <label class='col-md-2 col-form-label text-md-right' for='CREDIT_DATE'>_{TO}_</label>
        <div class='col-md-4'>
          <input id='CREDIT_DATE' type='text' name='CREDIT_DATE' value='%CREDIT_DATE%'
                 class='datepicker form-control d-0-9'> <!-- d-0-9: if admin's Customers>Credit (0-9) is disabled, make this input disabled. look at _make_perm_clases. -->
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CREDIT_TRESSHOLD'>_{CREDIT_TRESSHOLD}_:</label>
        <div class='col-md-8'>
          <div class='input-group mb-3'>
            <div class='input-group-prepend'>
              <button type='button' class='btn btn-danger'>_{DELETE}_</button>
            </div>
            <input type='text' id='CREDIT_TRESSHOLD' name='CREDIT_TRESSHOLD' value='%CREDIT_TRESSHOLD%'
                   class='form-control'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISABLED'>_{DISABLED}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='DISABLED' name='DISABLED' %DISABLED% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='UPLOAD_FILE'>_{ICON}_:</label>
        <div class='col-md-8'>
          <input type='file' name='UPLOAD_FILE' id='UPLOAD_FILE' value='%UPLOAD_FILE%'>
        </div>
      </div>
    </div>



    <div class='card mb-0 card-outline border-top card-big-form collapsed-card'>
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
          <label class='col-md-3' for='PERSONAL_TP'>_{PERSONAL}_ _{TARIF_PLAN}_</label>
          <div class='col-md-9'>
            <div class='input-group'>
              <input type='text' class='form-control' id='PERSONAL_TP' name='PERSONAL_TP' value='%PERSONAL_TP%'>
            </div>
          </div>
        </div>

      </div>
    </div>

    <div class='card-footer'>
      <!-- ACTION BTN -->
      <button type='submit' class='btn btn-primary float-left'>Left button</button>
      <!-- DEL BUTTON -->
      <button type='submit' class='btn btn-default float-right'>Right button</button>
    </div>
  </div>
</form>
