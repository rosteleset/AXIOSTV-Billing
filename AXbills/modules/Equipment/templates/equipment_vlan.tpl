<form class='form-horizontal'>

  <input type='hidden' name='action' value='%ACTION%'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='id' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>Vlan</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='NUMBER'>_{NUMBER}_:</label>
        <div class='col-md-9'>
          <input type='number' required class='form-control' id='NUMBER' name='NUMBER' value='%NUMBER%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='NAME'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input type='text' required class='form-control' id='NAME' name='NAME' value='%NAME%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <textarea type='text' class='form-control' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' value='%BUTTON%'>
    </div>
  </div>

</form>