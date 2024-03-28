<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{COMMUTATION}_ _{SEARCH}_</h4></div>
  <div class='card-body'>

    <!--<input type='hidden' name='index' value='$index'/>-->

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='ID_ID'>ID</label>
      <div class='col-md-8'>
        <input type='text' class='form-control' value='%ID%' name='ID' id='ID_ID'/>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='CONNECTER'>_{CONNECTER}_:</label>
      <div class='col-md-8'>
        %CONNECTER_ID_SELECT%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='WELL'>_{WELL}_:</label>
      <div class='col-md-8'>
        %WELL_ID_SELECT%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='CABLE'>_{CABLE}_:</label>
      <div class='col-md-8'>
        %CABLE_ID_SELECT%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='CREATED_ID'>_{CREATED}_:</label>
      <div class='col-md-8'>
        <input type='text' class='form-control datepicker' value='%CREATED%' name='CREATED' id='CREATED_ID'/>
      </div>
    </div>

  </div>
</div>
