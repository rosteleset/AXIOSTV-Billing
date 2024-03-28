<form name='CABLECAT_CABLE_TYPE' id='form_CABLECAT_CABLE_TYPE' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{CABLE_TYPE}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME_id'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id' placeholder=''
                 autocomplete="off"/>
        </div>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='FIBERS_COUNT_id'>_{FIBERS_COUNT}_:</label>
        <div class='col-md-8'>
          <input type='number' min='1' class='form-control' name='FIBERS_COUNT' value='%FIBERS_COUNT%'
                 id='FIBERS_COUNT_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MODULES_COUNT_id'>_{MODULES_COUNT}_:</label>
        <div class='col-md-8'>
          <input type='number' min='1' class='form-control' name='MODULES_COUNT' value='%MODULES_COUNT%'
                 id='MODULES_COUNT_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ATTENUATION_id'>_{ATTENUATION}_ (dBm / km):</label>
        <div class='col-md-8'>
          <input type='number' min='0' step='0.01' class='form-control' name='ATTENUATION' value='%ATTENUATION%'
                 id='ATTENUATION_id'/>
        </div>
      </div>


      <hr>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='COLOR_SCHEME_ID_SELECT'>_{COLOR_SCHEME}_:</label>
        <div class='col-md-8'>
          %COLOR_SCHEME_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='MODULES_COLOR_SCHEME_ID_SELECT'>_{MODULES}_
          _{COLOR_SCHEME}_:</label>
        <div class='col-md-8'>
          %MODULES_COLOR_SCHEME_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CAN_BE_SPLITTED'>_{CAN_BE_SPLITTED}_:</label>
        <div class='col-md-8'>
          <input type='checkbox' value='1' data-return='1'
                 name='CAN_BE_SPLITTED' id='CAN_BE_SPLITTED' data-checked='%CAN_BE_SPLITTED%'>
        </div>
      </div>

      <hr>

      <div class='form-group'>
        <h4 class='bg-lightblue'>_{MAP}_</h4>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='OUTER_COLOR_id'>_{OUTER_COLOR}_:</label>
        <div class='col-md-8'>
          <input type='color' class='form-control' name='OUTER_COLOR' id='OUTER_COLOR_id' value='%OUTER_COLOR%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LINE_WIDTH_id'>_{WIDTH}_, px:</label>
        <div class='col-md-8'>
          <input type='number' min='1' class='form-control' name='LINE_WIDTH' id='LINE_WIDTH_id' value='%LINE_WIDTH%'/>
        </div>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS_id'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
        </div>
      </div>


    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CABLECAT_CABLE_TYPE' id='go' class='btn btn-primary' name='submit'
             value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>

<script>
  var form = jQuery('#form_CABLECAT_CABLE_TYPE');
  var fibers_input = jQuery('#FIBERS_COUNT_id');
  var modules_input = jQuery('#MODULES_COUNT_id');

  form.on('submit', function (e) {
    var fibers_count = fibers_input.val();
    var modules_count = modules_input.val();

    if (fibers_count % modules_count != 0) {
      cancelEvent(e);

      fibers_input.parents('.form-group row').first().addClass('has-error');
      modules_input.parents('.form-group row').first().addClass('has-error');

      fibers_input.focus();
    }
  })
</script>