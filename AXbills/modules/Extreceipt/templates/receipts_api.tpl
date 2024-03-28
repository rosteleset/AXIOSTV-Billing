<form name='API' id='form_API' method='post' action='$SELF_URL'>

<div class='card card-primary card-outline container col-md-6'>
  <div class='card-header with-border'><h4 class='card-title'>_{SETTINGS}_</h4></div>
  <div class='card-body'>


      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='%SUBMIT_BTN_VALUE%'/>
      <input type='hidden' name='chg' value='%ID%'/>

      <div class='form-group row'>
          <label class='control-label col-md-3' for='CONF_NAME'>_{NAME}_:</label>
          <div class='col-md-9'>
              <input type='text' class='form-control' value='%CONF_NAME%' name='CONF_NAME' id='CONF_NAME'/>
          </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='API_NAME'>API plugin:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%API_NAME%' name='API_NAME' id='API_NAME'/>
        </div>
      </div>
      
      <div class='form-group row'>
        <label class='control-label col-md-3' for='LOGIN'>_{LOGIN}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%LOGIN%' name='LOGIN' id='LOGIN'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='PASSWORD'>_{PASSWD}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%PASSWORD%' name='PASSWORD' id='PASSWORD'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='URL'>URL:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%URL%' name='URL' id='URL'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='CALLBACK'>Callback url:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%CALLBACK%' name='CALLBACK' id='CALLBACK'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='INN'>INN:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%INN%' name='INN' id='INN'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='ADDRESS'>_{ADDRESS}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%ADDRESS%' name='ADDRESS' id='ADDRESS'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='EMAIL'>EMAIL:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%EMAIL%' name='EMAIL' id='EMAIL'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='GOODS_NAME'>_{ARTICLE}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%GOODS_NAME%' name='GOODS_NAME' id='GOODS_NAME'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='AID'>_{ADMIN}_:</label>
        <div class='col-md-9'>
          %AID%
        </div>
      </div>

  </div>
  <div class='card-footer'>
    <input type='submit' name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
  </div>
</div>
</form>