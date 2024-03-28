<form name='CABLECAT_CROSSES_TYPE' id='form_CABLECAT_CROSSES_TYPE' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{CROSS_TYPE}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME_ID'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_ID'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='CROSS_TYPE_ID'>_{CROSS_TYPE}_:</label>
        <div class='col-md-8'>
          %CROSS_TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='PANEL_TYPE_ID'>_{PANEL_TYPE}_:</label>
        <div class='col-md-8'>
          %PANEL_TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='RACK_HEIGHT_ID'>_{RACK_HEIGHT}_:</label>
        <div class='col-md-8'>
          <input type='number' min='0' class='form-control' value='%RACK_HEIGHT%' required name='RACK_HEIGHT'
                 id='RACK_HEIGHT_ID' placeholder='1'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='PORTS_TYPE_ID'>_{PORTS_TYPE}_:</label>
        <div class='col-md-8'>
          %PORTS_TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='POLISH_TYPE_ID'>_{POLISH_TYPE}_:</label>
        <div class='col-md-8'>
          %POLISH_TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='FIBER_TYPE_ID'>_{FIBER_TYPE}_:</label>
        <div class='col-md-8'>
          %FIBER_TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PORTS_COUNT_ID'>_{PORTS_COUNT}_:</label>
        <div class='col-md-8'>
          <input type='number' min='0' class='form-control' value='%PORTS_COUNT%' name='PORTS_COUNT' id='PORTS_COUNT_ID'
                 placeholder='8'/>
        </div>
      </div>
      
    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CABLECAT_CROSSES_TYPE' class='btn btn-primary' name='submit'
             value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>