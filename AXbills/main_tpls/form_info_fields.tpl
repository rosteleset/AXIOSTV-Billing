<div class='card card-primary card-outline container-sm'>
  <div class='card-header with-border'><h4 class='card-title'>_{INFO_FIELDS}_</h4></div>
  <div class='card-body'>
    <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
      <input type='hidden' name='ID' value='%ID%'/>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='NAME_ID'>_{NAME}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%NAME%' name='NAME' id='NAME_ID'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='SQL_FIELD_ID'>SQL_FIELD:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input %READONLY% required type='text' class='form-control' value='%SQL_FIELD%' name='SQL_FIELD'
                   id='SQL_FIELD_ID'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='TYPE'>_{TYPE}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>%TYPE_SELECT%</div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='PRIORITY_ID'>_{PRIORITY}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%PRIORITY%' name='PRIORITY' id='PRIORITY_ID'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='PATTERN'>_{TEMPLATE}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%PATTERN%' name='PATTERN' id='PATTERN'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='TITLE'>_{TIP}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%TITLE%' name='TITLE' id='TITLE'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='PLACEHOLDER'>_{PLACEHOLDER}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%PLACEHOLDER%' name='PLACEHOLDER' id='PLACEHOLDER'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='REQUIRED_ID'>_{REQUIRED_FIELD}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='REQUIRED_ID' %REQUIRED% name='REQUIRED' %REQUIRED%
                   value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='COMPANY_ID'>_{COMPANY}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='COMPANY_ID' %READONLY2% name='COMPANY' %COMPANY%
                   value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='USER_CHG_ID'>_{USER}_ _{CHANGE}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='USER_CHG_ID' name='USER_CHG' %USER_CHG% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='ABON_PORTAL_ID'>_{USER_PORTAL}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='ABON_PORTAL_ID' name='ABON_PORTAL' %ABON_PORTAL%
                   value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='MODULE_ID'>_{MODULE}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input type='text' class='form-control' value='%MODULE%' name='MODULE' id='MODULE_ID'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='COMMENT_ID'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <textarea class='form-control col-md-12' rows='2' name='COMMENT' id='COMMENT_ID'>%COMMENT%</textarea>
          </div>
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>