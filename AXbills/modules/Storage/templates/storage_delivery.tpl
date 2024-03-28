<form action='%SELF_URL%' method='POST'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='INSTALLATION_ID' value='%INSTALLATION_ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{STORAGE_DELIVERY}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input class='form-control' readonly value='%NAME%' id='NAME' name='NAME' type='text'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='DELIVERY_TYPE_ID'>_{DELIVERY_TYPE}_:</label>
        <div class='col-md-8'>
          %DELIVERY_TYPES_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TRACKING_NUMBER'>_{TRACKING_NUMBER}_:</label>
        <div class='col-md-8'>
          <input class='form-control' value='%TRACKING_NUMBER%' id='TRACKING_NUMBER' name='TRACKING_NUMBER' type='text'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DATE'>_{SEND_DATE}_:</label>
        <div class='col-md-8'>
          %DATE%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea id='COMMENTS' name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name='%ACTION%' value='_{SAVE}_'>
    </div>
  </div>
</form>
