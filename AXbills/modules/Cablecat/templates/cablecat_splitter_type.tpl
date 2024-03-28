<form name='CABLECAT_SPLITTER' id='form_CABLECAT_SPLITTER' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{SPLITTER_TYPE}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME_ID'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_ID'/>
        </div>
      </div>

      <div class='radio'>
        <label>
          <input type='radio' name='TYPE_NAME' id='SPLITTER_TYPE_FBT_id' value='FBT'>
          FBT
        </label>
      </div>
      <div class='radio'>
        <!--TODO: checked-->
        <label>
          <input type='radio' name='TYPE_NAME' id='SPLITTER_TYPE_PLC_id' value='PLC'>
          PLC
        </label>
      </div>


      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='IN_ID'>_{FIBERS_IN}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' value='%FIBERS_IN%' required name='FIBERS_IN' id='IN_ID'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='OUT_ID'>_{FIBERS_OUT}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' value='%FIBERS_OUT%' required name='FIBERS_OUT' id='OUT_ID'/>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CABLECAT_SPLITTER' class='btn btn-primary' name='submit'
             value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>
