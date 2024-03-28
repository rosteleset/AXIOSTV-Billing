<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{SERVICE}_ _{STATUS}_</h4></div>
    <div class='card-body'>

      <div class="form-group row">
        <label class='col-md-3 control-label required' for='ID'>_{NUM}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text' required>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label required' for='NAME'>_{NAME}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text' required>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='COLOR'>_{COLOR}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input class='form-control' type='color' name='COLOR' id='COLOR' value='%COLOR%'/>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='TYPE'>_{TYPE}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            %TYPE_SEL%
          </div>
        </div>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" type="checkbox" id="GET_FEES" name="GET_FEES" %GET_ABON_CHECKED% value='1'>
        <label for="GET_FEES" class="custom-control-label">_{GET_FEES}_</label>
      </div>

      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</form>
