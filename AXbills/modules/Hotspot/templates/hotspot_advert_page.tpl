<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{SETTINGS}_</h4></div>
  <div class='card-body'>

    <form name='HOTSPOT_ADVERT' id='form_HOTSPOT_ADVERT' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='%SUBMIT_BTN_VALUE%'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME_id'>Hotspot</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%HOSTNAME%' name='HOSTNAME' id='NAME_id'/>
        </div>
      </div>
      
      <div class='form-group'>
        <label class='control-label col-md-3' for='ACTION_id'>Key</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%ACTION%' name='ACTION' id='ACTION_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='URL_id'>Value</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='PAGE' id='URL_id'>%PAGE%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_HOTSPOT_ADVERT' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>
