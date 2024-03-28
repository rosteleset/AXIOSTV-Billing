<form action=$SELF_URL METHOD=post class='form-horizontal'>
    <input type=hidden name=index value='$index'>
    <input type=hidden name=UID value='$FORM{UID}'>
    <input type=hidden name=ID value='$FORM{ID}'>
    <input type=hidden name=send_message value='1'>
    <fieldset>
        <div class='card card-primary card-outline box-form'>

            <legend>_{SEND}_ _{MESSAGE}_</legend>
            <div class='card-body'>
                <div class='form-group'>
                    <label class='control-label col-md-4' for='MESSAGE'>_{NUM}_:</label>
                    <div class='col-md-8'>
                        <textarea name='MESSAGE' class='form-control' type='password'>%MESSAGE%</textarea>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-4' for='REBOOT_AFTER_OK'>_{REBOOT}_: </label>
                    <div class='col-md-8'>
                        <input name='REBOOT_AFTER_OK' type='checkbox' value=1>
                    </div>
                </div>
            </div>

            <div class='card-footer'>
                <input class='btn btn-primary btn-sm' type=submit name=send value='_{SEND}_'>
            </div>
        </div>
    </fieldset>
</form>
