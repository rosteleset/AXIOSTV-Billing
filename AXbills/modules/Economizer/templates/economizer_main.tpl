<form action='$SELF_URL' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='EXISTING' value='%EXISTING%'>
  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{SETTINGS_FORM}_</h4>
    </div>
    <div class='card-body'>
      <div class="form-group text-center align-center">
          <label class="control-label">_{RESOURSE_104}_</label>
          <br>
      </div>
      <div class="form-group row">
        <label class="control-label col-sm-2">_{LOGIN}_</label>
        <div class="col-md-8 col-sm-9">
          %LOGIN104%
        </div>
      </div>
      <div class="form-group row">
        <label class="control-label col-sm-2">_{PASSWORD}_</label>
        <div class="col-md-8 col-sm-9">
          %PASSWORD104%
        </div>
      </div>

      <div class="form-group text-center align-center">
        <label class="control-label">_{RESOURSE_ELECTRO}_</label>
        <br>
      </div>
      <div class="form-group row">
        <label class="control-label col-sm-2">_{LOGIN}_</label>
        <div class="col-md-8 col-sm-9">
          %LOGIN_ELECTRO%
        </div>
      </div>
      <div class="form-group row">
        <label class="control-label col-sm-2">_{PASSWORD}_</label>
        <div class="col-md-8 col-sm-9">
          %PASSWORD_ELECTRO%
        </div>
      </div>
      <div class="text-center align-center">
        %BUTTON_ADD%
      </div>
    </div>
  </div>
</form>
