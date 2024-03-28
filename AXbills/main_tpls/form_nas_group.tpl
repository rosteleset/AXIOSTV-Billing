<form class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='$FORM{chg}'/>

  <div class="card card-primary card-outline">
    <div class="card-header with-border">
      <h3 class="card-title">_{NAS}_ - _{GROUPS}_</h3>
    </div>
    <div class="card-body">
      <div class='form-group row'>
        <label  class='col-sm-2 col-form-label' for='NAME'>_{NAME}_</label>
        <div class='col-sm-10'>
          <input id='NAME' value='%NAME%' name='NAME' placeholder='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label  class='col-sm-2 col-form-label' for='DISABLE'>_{DISABLE}_</label>
        <div class='col-sm-10'>
          <input id='DISABLE' value='1' name='DISABLE' class='form-control' type='checkbox' %DISABLE%>
        </div>
      </div>

      <div class='form-group row'>
        <label  class='col-sm-2 col-form-label' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-sm-10'>
          <textarea class='form-control' id='COMMENTS' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <div class='col-sm-offset-2 col-sm-8'>
          <input type='submit' class='btn btn-primary btn-sm float-left' name='%ACTION%' value='%LNG_ACTION%'>
        </div>
      </div>
    </div>
  </div>
</form>
