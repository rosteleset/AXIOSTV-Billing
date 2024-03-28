<form name='API' id='form_API' method='post' action=$SELF_URL>
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
        <label class='control-label col-md-3' for='METHODS'>_{PAYMENT_METHOD}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%METHODS%' name='METHODS' id='METHODS'/>
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