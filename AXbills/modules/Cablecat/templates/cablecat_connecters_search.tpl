<form name='CABLECAT_CONNECTERS' id='form_CABLECAT_CONNECTERS' method='post' class='form form-horizontal'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{CONNECTER}_</h4></div>
    <div class='card-body'>
      
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ID_id'>ID:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='ID' value='%ID%' id='ID_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME_ID'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' value='%NAME%' name='NAME'
                 id='NAME_ID'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TYPE_ID'>_{CONNECTER_TYPE}_:</label>
        <div class='col-md-8'>
          %CONNECTER_TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='WELL_ID'>_{WELL}_:</label>
        <div class='col-md-8'>
          %WELL_ID_SELECT%
        </div>
      </div>

    </div>
  </div>
</form>
