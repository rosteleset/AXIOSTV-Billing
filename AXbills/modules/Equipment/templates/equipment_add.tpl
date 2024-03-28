<form action='$SELF_URL' METHOD='post' name='FORM_NAS' ID='FORM_NAS' class='form-horizontal' role='form'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='add_form' value='1'>
  <input type='hidden' name='NAS_ID' value='%NAS_ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{EQUIPMENT}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required'>IP:</label>
        <div class='col-md-8'>
          <input type=text class='form-control ip-input' required id='NAS_IP'
                 placeholder='%IP%' name='IP' value='%NAS_IP%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required'>_{NAME}_ (a-zA-Z0-9_):</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' id='NAS_NAME' placeholder='%NAS_NAME%'
                 name='NAS_NAME'
                 value='%NAS_NAME%' required pattern='^\\w*\$' maxlength='30'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <input class='form-control' id='NAS_DESCRIBE' placeholder='%NAS_DESCRIBE%'
                 name='NAS_DESCRIBE'
                 value='%NAS_DESCRIBE%'>
        </div>
      </div>

      <div class='form-group'>
        <div class='form-check'>
          <input class='form-check-input' type='checkbox' id='NAS_DISABLE' name='NAS_DISABLE' value='1' %NAS_DISABLE%>
          <label class='form-check-label'>_{DISABLE}_</label>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{MANAGE}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='NAS_MNG_I'>IP:</label>
            <div class='col-md-8'>
              <input id='NAS_MNG_IP' name='NAS_MNG_IP' value='%NAS_MNG_IP%'
                     placeholder='IP' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COA_PORT'>POD/COA:</label>
            <div class='col-md-8'>
              <input id='COA_PORT' name='COA_PORT' value='%COA_PORT%'
                     placeholder='PORT' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='SSH_PORT'>SSH:</label>
            <div class='col-md-8'>
              <input id='SSH_PORT' name='SSH_PORT' value='%SSH_PORT%'
                     placeholder='PORT' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='SNMP_PORT'>SNMP:</label>
            <div class='col-md-8'>
              <input id='SNMP_PORT' name='SNMP_PORT' value='%SNMP_PORT%'
                     placeholder='PORT' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='NAS_MNG_USER'>_{USER}_:</label>
            <div class='col-md-8'>
              <div class='input-group'>
                <input id='NAS_MNG_USER' name='NAS_MNG_USER' value='%NAS_MNG_USER%'
                       placeholder='%NAS_MNG_USER%'
                       class='form-control' type='text'>
                <div class='input-group-append'>
                  <a href='$SELF_URL?qindex=$index&NAS_ID=%NAS_ID%&create=1&ssh_key=1'
                     class='btn input-group-button' target='_new' title='_{CREATE}_ SSH public key'>
                    <i class='fa fa-key'></i>
                  </a>
                  <a href='$SELF_URL?qindex=$index&NAS_ID=%NAS_ID%&download=1&ssh_key=1'
                     class='btn input-group-button' target='_new' title='_{DOWNLOAD}_ SSH public key'>
                    <i class='fa fa-download'></i>
                  </a>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='NAS_MNG_PASSWORD'>
              _{PASSWD}_ (PoD, RADIUS Secret, SNMP community):
            </label>
            <div class='col-md-8'>
              <input id='NAS_MNG_PASSWORD' name='NAS_MNG_PASSWORD' class='form-control'
                     type='password' autocomplete='new-password'>
            </div>
          </div>
        </div>
      </div>

      %ADDRESS_FORM%

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{EXTRA}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div id='nas_misc' class='card-body'>
          %NAS_ID_FORM%

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='MAC'>MAC:</label>
            <div class='col-md-8'>
              <input id='MAC' name='MAC' value='%MAC%' placeholder='%MAC%' class='form-control'
                     type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='NAS_GROUPS'>_{GROUP}_:</label>
            <div class='col-md-8'>
              %NAS_GROUPS_SEL%
            </div>
          </div>
          <div>
            %EXTRA_PARAMS%
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
    </div>

  </div>
</form>
