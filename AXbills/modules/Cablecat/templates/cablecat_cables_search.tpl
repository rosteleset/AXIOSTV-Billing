<form name='CABLECAT_CABLE' id='form_CABLECAT_CABLE' method='post' class='form form-horizontal'>
  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{CABLE}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ID_id'>ID:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='ID' value='%ID%' id='ID_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME_id'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TYPE_ID'>_{CABLE_TYPE}_:</label>
        <div class='col-md-8'>
          %CABLE_TYPE_SELECT%
        </div>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{WELL}_ 1:</label>
        <div class='col-md-8'>
          %WELL_1_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{WELL}_ 2:</label>
        <div class='col-md-8'>
          %WELL_2_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LENGTH_F_id'>_{LENGTH}_, _{METERS_SHORT}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='LENGTH' value='%LENGTH%' id='LENGTH_F_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESERVE_id'>_{RESERVE}_, _{METERS_SHORT}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='RESERVE' value='%RESERVE%' id='RESERVE_id'/>
        </div>
      </div>

    </div>
  </div>
</form>