<div class='row'>
  <form name='EVENTS_PRIORITY_SEND_TYPE' id='form_EVENTS_PRIORITY_SEND_TYPE' method='post'
        class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='save' value='1'/>
    <input type='hidden' name='AID' value='%AID%'/>

    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'><h4 class='card-title'>_{NOTIFICATION_TYPE_FOR_PRIORITY}_</h4></div>
      <div class='card-body'>
        <div class='row'>
          <div class='col-md-4'>
            <p class='text-muted'><strong>_{PRIORITY}_</strong></p>
          </div>
          <div class='col-md-8'>
            <p class='text-muted'><strong>_{NOTIFICATION_TYPE}_</strong></p>
          </div>
        </div>
        <hr style='margin: 0 5px'>
        <div class='row'>
          <ul class='nav flex-column'>

            %TABS_MENU%
          </ul>

          <div class='tab-content col-md-8'>
            %TABS%
          </div>
        </div>
      </div>
      <div class='card-footer'>
        <input type='submit' form='form_EVENTS_PRIORITY_SEND_TYPE' class='btn btn-primary' name='submit'
               value='_{SAVE}_'>
      </div>
    </div>

  </form>
</div>
