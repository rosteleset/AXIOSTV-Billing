<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{PRIORITY}_</h4></div>
  <div class='card-body'>

    <form name='EVENTS_PRIORITY_FORM' id='form_EVENTS_PRIORITY_FORM' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='PRIORITY_NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%'
                 id='PRIORITY_NAME_id' placeholder='_{PRIORITY}_'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='PRIORITY_VALUE_id'>_{VALUE}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='VALUE' value='%VALUE%'
                 id='PRIORITY_VALUE_id'/>
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_EVENTS_PRIORITY_FORM' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

