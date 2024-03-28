<div class='card card-primary card-outline card-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{LOG}_</h4></div>
  <div class='card-body'>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='LID'>_{LEAD}_ (*,):</label>
      <div class='col-md-8'>
        <input id='LID' name='LID' value='%LID%' class='form-control' type='text'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='ADMIN' class='control-label col-md-4'>_{ADMIN}_:</label>
      <div class='col-md-8'>
        %ADMIN_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label for='ACTIONS' class='control-label col-md-4'>_{CHANGE}_ (*):</label>
      <div class='col-md-8'>
        <input class='form-control' id='ACTIONS' placeholder='%ACTIONS%' name='ACTIONS' value='%ACTIONS%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='TYPE_SEL' class='control-label col-md-4'>_{TYPE}_:</label>
      <div class='col-md-8'>
        %TYPE_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label for='IP' class='control-label col-md-4'>IP:</label>
      <div class='col-md-8'>
        <input class='form-control' id='IP' placeholder='%IP%' name='IP' value='%IP%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='FROM_DATE/TO_DATE' class='control-label col-md-4'>_{PERIOD}_:</label>
      <div class='col-md-8'>
        %PERIOD%
      </div>
    </div>

  </div>
</div>
