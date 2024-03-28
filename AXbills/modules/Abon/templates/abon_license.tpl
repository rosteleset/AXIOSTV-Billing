<form action='%SELF_URL%' method='POST' id='license_form'>
  <input class='form-control' type='hidden' name='index' value='%index%'/>
  <input class='form-control' type='hidden' name='add' value='%TP_ID%'/>
  <input class='form-control' type='hidden' name='sid' value='%sid%'/>

  <div class='card card-primary card-outline container-md col-md-12'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{LICENSE}_</h4>
    </div>

    <div class='card-body'>
      %LICENSE_FORM%

      <div class='col-md-12'>
        <div class='form-check'>
          <input type='checkbox' data-return='1' class='form-check-input' id='ACCEPT_LICENSE'
                 name='ACCEPT_LICENSE' value='1' required>
          <label class='form-check-label' for='ACCEPT_LICENSE'>_{ACCEPT}_</label>
        </div>

      </div>

    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary double_click_check hidden_empty_required_filed_check' name='ACCEPT' value='_{ACCEPT}_'/>
    </div>

  </div>
</form>