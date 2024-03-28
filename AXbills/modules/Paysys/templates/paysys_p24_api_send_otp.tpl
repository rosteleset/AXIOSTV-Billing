<form method='POST' action='$SELF_URL' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='SESSION_ID' value='%SESSION_ID%'>

    <div class='card box-primary'>

        <div class='card-header with-border text-center'><h4 class='card-title'>SEND OTP</h4></div>
        <div class='card-body'>

            <div class='form-group'>
                <label class='col-md-3 control-label required'>OTP:</label>
                <div class='col-md-9'><input class='form-control' type='text'name='OTP' autofocus>
                </div>
            </div>

        </div>

        <div class='card-footer'><input class='btn btn-primary' type='submit' name='send' value='_{SEND}_'></div>
    </div>


</form>