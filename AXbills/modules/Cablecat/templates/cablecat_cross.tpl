<form name='CABLECAT_CROSS' id='form_CABLECAT_CROSS' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{CROSS}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME_ID'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_ID' autocomplete="off"/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='WELL_ID'>_{WELL}_:</label>
        <div class='col-md-8'>
          %WELL_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COLOR_SCHEME_ID_SELECT'>_{COLOR_SCHEME}_:</label>
        <div class='col-md-8'>
          %COLOR_SCHEME_ID_SELECT%
        </div>
      </div>

      %OBJECT_INFO%
      
    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CABLECAT_CROSS' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>

%CROSS_LINKS_TABLE%