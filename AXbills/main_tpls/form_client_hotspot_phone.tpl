<form action='$SELF_URL' METHOD='POST' class='form-inline'>
    <input type=hidden name='mac' value='%mac%'>
    <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>
    <input type=hidden name='server_name' value='%server_name%'>
    <input type=hidden name='link_login_only' value='%link_login_only%'>

    <fieldset>
        <div class='card card-primary card-outline'>
            <div class='card-body'>
                <div class='form-group'>
                    <label class='control-label' for='PHONE'>_{PHONE}_</label>

                    <div class='input-group'>
                      <span class='input-group-addon' id='basic-addon1'>+%PHONE_PREFIX%</span>
                      <input type='text' id='PHONE' required='required' name='PHONE' class='form-control'/>
                    </div>
                        <input type='submit' id='get' name='get' value='_{REGISTRATION}_' class='btn btn-primary'/>
                </div>
            </div>
        </div>

    </fieldset>
</form>

