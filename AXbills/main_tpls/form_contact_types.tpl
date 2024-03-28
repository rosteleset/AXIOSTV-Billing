<form name='contact_types' id='form_contact_types' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{CONTACTS}_ _{TYPES}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME_id'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='IS_DEFAULT_id'>_{DEFAULT}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='IS_DEFAULT_id' name='IS_DEFAULT' %IS_DEFAULT_CHECKED%
                   value='1' data-return='1'>
          </div>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' form='form_contact_types' class='btn btn-primary' name='submit'
             value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>



