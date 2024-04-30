<form class='form-horizontal' name='expert'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='module' value='Expert'>
  <div class='col-md-6'>
    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'><h3 class='card-title'>Ссылки для получения информации</h3></div>
      <div class='card-body'>
        <div class='col-md-12'>

          <div class="form-group">
            <label class='control-label col-md-3' for='server'>АСР КАЗНА 39 server address</label>
            <div class='col-md-9'>
              <input name='server' value='%server%' class='form-control' type='text' placeholder='https://demo.billing.axiostv.ru:9443/admin/index.cgi'>
            </div>
          </div>

          <div class="form-group">
            <label class='control-label col-md-3' for='api_key'>API KEY</label>
            <div class='col-md-9'>
              <input name='api_key' value='%api_key%' class='form-control' type='text'>
            </div>
          </div>

        </div>
      </div>
      <div class='card-footer'>
        <input type='submit' name='change_links' value='Изменить' class='btn btn-primary'>
      </div>  
    </div>
  </div>
</form>
