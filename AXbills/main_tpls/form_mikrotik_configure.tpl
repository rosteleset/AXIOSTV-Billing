<form method='post' action='$SELF_URL' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'/>
  <input type='hidden' name='CONNECTION_TYPE' value='$FORM{CONNECTION_TYPE}'/>
  <input type='hidden' name='mikrotik_configure' value='1'/>
  <input type='hidden' name='subf' value=''/>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{CONFIGURATION}_ : $FORM{CONNECTION_TYPE}</h4>
      <div class='float-right'>%CLEAN_BTN%</div>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='RADIUS_IP_ID'>RADIUS IP</label>
        <div class='col-md-9'>
          %RADIUS_IP_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='DNS_ID'>DNS (,)</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%DNS%' name='DNS' id='DNS_ID'/>
        </div>
      </div>

      <!--
            <div class='form-group row'>
              <label class='control-label col-md-3' for='CLIENTS_POOL_ID'>IP Pool</label>
              <div class='col-md-9'>
                %IP_POOL_SELECT%
              </div>
            </div>
      -->

      <div class='checkbox text-center'>
        <label>
          <input type='checkbox' data-return='1' data-checked='%USE_NAT%' data-input-enables='NEGATIVE_BLOCK' value='1' name='USE_NAT' id='USE_NAT_ID'/>
          <strong>NAT (Masquerade)</strong>
        </label>
      </div>

      <hr/>

      <!--extra-->
      %EXTRA_INPUTS%
      <!--extra-->

      <div class='form-group'>
        <div class='card card-primary card-outline'>
          <div class='card-header text-center' role='tab' id='EXTRA_OPTIONS_heading'>
            _{EXTRA}_
          </div>
          <div class='card-body'>

            <div class='form-group row'>
              <label class='control-label col-md-3' for='RADIUS_IP_ID'>_{INTERNAL_NETWORK}_</label>
              <div class='col-md-9'>
                %INTERNAL_NETWORK_SELECT%
              </div>
            </div>

            <div class='text-left col-md-offset-3 col-lg-offset-3'>
              %EXTRA_OPTIONS%
            </div>
          </div> <!-- end of collapse panel -->
        </div> <!-- end of collapse form-group -->

      </div>

      <div class='card-footer'>
        <input type='submit' class='btn btn-primary' name='action' value='_{APPLY}_'>
      </div>
    </div>
  </div>
</form>