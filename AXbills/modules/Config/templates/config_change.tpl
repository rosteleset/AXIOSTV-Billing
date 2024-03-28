<script src='/styles/default/js/modules/config/config.js'></script>
<form action='%SELF_URL%' method='POST'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='MODULE' value='%MODULE%'>
  <input type='hidden' name='PARAM' value='%CONFIG_VARIABLE%'>

  <div class='card card-outline card-primary container-md'>
    <div class='card-header'>
      <h2 class='card-title'>_{CONFIGURATION}_ _{CHANGE}_</h2>
    </div>
    <div class='card-body'>
      <div class='form-group row mx-0'>
        <label for='NAME' class='col-form-label text-md-right col-md-4'>_{VARIABLE}_:</label>
        <div class='col-md-8'>
          <div class='col-form-label' id='NAME'>%CONFIG_VARIABLE%</div>
        </div>
      </div>

      <div class='form-group row mx-0'>
        <div class='col-md-12 px-5 pb-3'>
          %COMMENTS%
        </div>
      </div>
       %VALUE%
    </div>
    <div class='card-footer'>
      <input type='submit' name='change' value='_{CHANGE}_' class='btn btn-primary'>
    </div>
  </div>
</form>
