<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{ROUTE}_ _{GROUP}_</h4></div>
  <div class='card-body'>

    <form name='maps_route_groups' id='form_maps_route_groups' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='ID' value='$FORM{chg}' />
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control'  name='NAME'  value='%NAME%'  id='NAME_id'  placeholder=''  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control'  rows='5'  name='COMMENTS'  id='COMMENTS_id' >%COMMENTS%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PARENT_ID'>_{PARENT_F}_ _{GROUP}_</label>
        <div class='col-md-9'>
          %PARENT_GROUP%
        </div>
      </div>

    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_maps_route_groups' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>