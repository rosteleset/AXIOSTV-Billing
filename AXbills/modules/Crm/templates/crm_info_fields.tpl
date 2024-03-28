<form name='form_crm_info_fields' id='form_crm_info_fields' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{INFO_FIELDS}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME_ID'>_{NAME}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%NAME%' name='NAME' id='NAME_ID'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SQL_FIELD_ID'>SQL_FIELD:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input %READONLY% required type='text' class='form-control' value='%SQL_FIELD%' name='SQL_FIELD'
                   id='SQL_FIELD_ID'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TYPE'>_{TYPE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>%TYPE_SELECT%</div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PRIORITY_ID'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%PRIORITY%' name='PRIORITY' id='PRIORITY_ID'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PATTERN'>_{TEMPLATE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%PATTERN%' name='PATTERN' id='PATTERN'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TITLE'>_{TIP}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%TITLE%' name='TITLE' id='TITLE'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PLACEHOLDER'>_{PLACEHOLDER}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%PLACEHOLDER%' name='PLACEHOLDER' id='PLACEHOLDER'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENT_ID'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <textarea class='form-control col-md-12' rows='2' name='COMMENT' id='COMMENT_ID'>%COMMENT%</textarea>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='REGISTRATION'>_{CRM_SHOW_AT_REGISTRATION}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='REGISTRATION' name='REGISTRATION' %REGISTRATION% value='1'>
          </div>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' form='form_crm_info_fields' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>

</form>