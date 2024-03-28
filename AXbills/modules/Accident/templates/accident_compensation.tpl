<form METHOD=POST class='form-horizontal' name='COMPENSATION_ACCIDENT'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='type_id' value='%TYPE_ID%'>
  <input type='hidden' name='address' value='%ADDRESS%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{COMPENSATION}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-3'>_{SERVICE}_:</label>
        <div class='col-md-8 col-sm-9'>
          %SERVICE%
        </div>
      </div>

      %ADDRESS_FORM%
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary float-right' name='COMPENSATION' value='_{COMPENSATION}_'>
    </div>
  </div>
</form>