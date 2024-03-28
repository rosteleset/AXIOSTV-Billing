<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{ROUTE}_ _{TYPES}_</h4></div>
  <div class='card-body'>

    <form name='maps_route_types' id='form_maps_route_types' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='$FORM{chg}' />
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COLOR_id'>_{COLOR}_</label>
        <div class='col-md-9'>
          <input type='color' class='form-control' name='COLOR' value='%COLOR%' id='COLOR_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='FIBERS_id'>_{FIBERS}_</label>
        <div class='col-md-9'>
          <input type='number' class='form-control' min="1" name='FIBERS' value='%FIBERS%' id='FIBERS_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='LINE_WIDTH_id'>_{LINE_WIDTH}_, px</label>
        <div class='col-md-9'>
          <input type='number' class='form-control' min="1" max="20" name='LINE_WIDTH' value='%LINE_WIDTH%' id='LINE_WIDTH_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_maps_route_types' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

