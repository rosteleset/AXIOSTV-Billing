<form name='CABLECAT_WELLS' id='form_CABLECAT_WELLS' method='post' class='form form-horizontal'>
  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{WELL}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ID_id'>ID:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='ID' value='%ID%' id='ID_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right ' for='NAME_ID'>_{NAME}_:</label>

        <div class='col-md-8'>
          <input type='text' class='form-control' value='%NAME%' name='NAME' id='NAME_ID'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right ' for='TYPE_ID_SELECT'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='INSTALLED_ID'>_{INSTALLED}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control datepicker' value='%INSTALLED%' name='INSTALLED'
                 id='INSTALLED_ID'/>
        </div>
      </div>

      <div class='form-group row should-be-hidden'>
        <label class='col-md-4 col-form-label text-md-right' for='POINT_ID'>_{OBJECT}_:</label>
        <div class='col-md-8'>
          %POINT_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PARENT_ID'>_{INSIDE}_:</label>
        <div class='col-md-8'>
          %PARENT_ID_SELECT%
        </div>
      </div>
      
    </div>
  </div>
</form>