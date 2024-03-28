<form action='$SELF_URL' METHOD='POST' class='form-inline' name=admin_form>
    <input type=hidden name='GUEST_ACCOUNT' value='1'>
    <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>
    <input type=hidden name='LOGIN' value='%LOGIN%'>
    <input type=hidden name='UID' value='%UID%'>
    <input type=hidden name='PHONE' value='%PHONE%'>
    <input type=hidden name='mac' value='%mac%'>

    <fieldset>
        <div class='card card-primary card-outline'>
            <div class='card-body'>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='PIN'>PIN:</label>
                    <div class='col-md-7'>
                        <input id='PIN' name='PIN' value='%PIN%' placeholder='xxxx'
                                class='form-control' type='text'>
                    </div>
                    <div class='col-md-2'>
                        <input type='submit' class='btn btn-primary' name='SEND' value='_{ENTER}_'>
                    </div>
                </div>
                <br>
            </div>
        </div>

    </fieldset>
    %BUTTON%
</form>
