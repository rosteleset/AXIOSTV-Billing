<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{ADVERTISE}_ _{CONFIG}_ : MikroTik</h4></div>
  <div class='card-body'>

    <form name='HOTSPOT_CONFIG' id='form_HOTSPOT_CONFIG' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}' />

      <div class='form-group'>
        <label class='control-label col-md-3' for='PERIOD_id'>_{PERIOD}_, s</label>
        <div class='col-md-9'>
          <input required='required' type='text' class='form-control'  name='PERIOD'  value='%PERIOD%'  id='PERIOD_id'  />
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_HOTSPOT_CONFIG' class='btn btn-primary' name='action' value='_{SET}_'>
  </div>
</div>