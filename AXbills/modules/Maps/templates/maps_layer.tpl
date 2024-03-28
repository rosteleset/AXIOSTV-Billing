<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{MAP}_ : _{LAYERS}_</h4></div>
  <div class='card-body'>

    <form name='MAPS_LAYER' id='form_MAPS_LAYER' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='ID' value='$FORM{chg}' />
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control'  required name='NAME'  value='%NAME%'  id='NAME_id'  />
        </div>
      </div>

      <div class='checkbox text-center'>
        <label>
          <input type='checkbox' data-checked='%MARKERS_IN_CLUSTER%' data-return='1' name='MARKERS_IN_CLUSTER'  id='MARKERS_IN_CLUSTER_id'  />
          <strong>_{CLUSTERS}_</strong>
        </label>
      </div>

      <hr/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control'  rows='5'  name='COMMENTS'  id='COMMENTS_id' >%COMMENTS%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_MAPS_LAYER' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

