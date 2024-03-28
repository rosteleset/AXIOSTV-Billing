<form name='KKT' id='FORM_KKT' method='post'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='chg' value='%ID%'/>

  <div class='card card-primary card-outline container col-md-6'>
    <div class='card-header with-border'><h4 class='card-title'>_{SETTINGS}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='API_ID'>API:</label>
        <div class='col-md-9'>
          %API_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='KKT_GROUP'>KKT _{GROUP}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%KKT_GROUP%' name='KKT_GROUP' id='KKT_GROUP'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='KKT_KEY'>KKT _{LICENSE}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%KKT_KEY%' name='KKT_KEY' id='KKT_KEY'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='CHECK_HEADER'>_{CHECK}_ Header:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%CHECK_HEADER%' name='CHECK_HEADER' id='CHECK_HEADER'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='CHECK_DESC'>_{CHECK}_ Desc:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%CHECK_DESC%' name='CHECK_DESC' id='CHECK_DESC'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='CHECK_FOOTER'>_{CHECK}_ Footer:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%CHECK_FOOTER%' name='CHECK_FOOTER' id='CHECK_FOOTER'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='METHODS'>_{PAYMENT_METHOD}_:</label>
        <div class='col-md-9'>
          %METHODS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='GROUPS'>_{GROUPS}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%GROUPS%' name='GROUPS' id='GROUPS'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='AID'>_{ADMIN}_:</label>
        <div class='col-md-9'>
          %ADMINS_SEL%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
    </div>
  </div>
</form>
