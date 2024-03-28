<div class='card container-md' style='max-width: 756px'>
  <div class="card-header with-border">
    <h3 class="card-title">_{CAMERAS}_: _{GROUP}_</h3>
  </div>
  <div class='card-body'>
    <form method='POST' action='$SELF_URL' class='form-horizontal'>
      <input type='hidden' name='index' value='$index'>
      <input type='hidden' name='ID' value='%ID%'>
      <div class='form-group row'>
        <label class='control-label col-md-4 required'>_{SERVICE}_:</label>
        <div class='col-md-8'>
          %SERVICES_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for="NAME">_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' id="NAME" name='NAME' value='%NAME%'/>
        </div>
      </div>

      %ADDRESS%

      <div class='form-group row'>
        <label class='control-label col-md-4' for="MAX_USERS">Max. _{USERS}_:</label>
        <div class='col-md-8'>
          <input type='number' class='form-control' id="MAX_USERS" name='MAX_USERS' value='%MAX_USERS%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for="MAX_CAMERAS">Max. _{CAMERAS}_:</label>
        <div class='col-md-8'>
          <input type='number' class='form-control' id="MAX_CAMERAS" name='MAX_CAMERAS' value='%MAX_CAMERAS%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for="COMMENT">_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='5' id="COMMENT" name='COMMENT'>%COMMENT%</textarea>
        </div>
      </div>

      <div class='card-footer'>
        <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
      </div>
    </form>
  </div>
</div>
