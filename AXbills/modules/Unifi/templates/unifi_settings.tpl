<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>UniFi _{SETTINGS}_</h4></div>
    <div class='card-body'>

        <form name='UNIFI_SETTINGS' id='form_UNIFI_SETTINGS' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index' />

            <div class='form-group'>
                <label class='control-label col-md-3' for='UNIFI_URL_id'>UniFi URL</label>
                <div class='col-md-9'>
                    <input readonly type='text' class='form-control'  name='UNIFI_URL'  value='%UNIFI_URL%'  id='UNIFI_URL_id'  />
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='BILLING_URL_id'>Billing URL</label>
                <div class='col-md-9'>
                    <input readonly type='text' class='form-control'  name='BILLING_URL'  value='%BILLING_URL%'  id='BILLING_URL_id'  />
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='UNIFI_IP_id'>UniFi IP</label>
                <div class='col-md-9'>
                    <input readonly type='text' class='form-control'  name='UNIFI_IP'  value='%UNIFI_IP%'  id='UNIFI_IP_id'  />
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='UNIFI_USER_id'>_{LOGIN}_</label>
                <div class='col-md-9'>
                    <input readonly type='text' class='form-control'  name='UNIFI_USER'  value='%UNIFI_USER%'  id='UNIFI_USER_id'  />
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='UNIFI_PASS_id'>_{PASSWD}_</label>
                <div class='col-md-9'>
                    <input readonly type='password' class='form-control'  name='UNIFI_PASS'  value='**********'  id='UNIFI_PASS_id'  />
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='UNIFI_VERSION'>_{VERSION}_</label>
                <div class='col-md-9'>
                    %UNIFI_VERSION%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='UNIFI_SITENAME_id'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input readonly type='text' class='form-control'  name='UNIFI_SITENAME'  value='%UNIFI_SITENAME%'  id='UNIFI_SITENAME_id'  />
                </div>
            </div>
        </form>

    </div>
</div>

            