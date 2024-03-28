<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='MAIL_SEND' value='1'>
    <input type='hidden' name='module' value='Price'>
    <input type='hidden' name='E_MAIL_2' value='%E_MAIL%'>
    <div class='card box-primary'>
        <div class='card-header with-border'>
            <h3 class='card-title'>
                <div class='row'>
                    <div class='col-md-11 col-md-offset-1'>
                        <h2><span class='fa fa-fw fa-wrench'></span>_{SUPPORT}_</h2>
                    </div>
                    <div class='col-md-11 col-md-offset-1'><h4>_{PACKAGE_SUPPORT}_</h4></div>
                </div>
            </h3>
        </div>
        <div class="card-body">
            <div class="form-group">
                <label class="col-md-3 control-element">_{YOU_ALREADY_HAVE_A_FORM}_</label>
                <div class='col-md-2'>
                    <button class='btn btn-block btn-primary' type='submit' name='OPEN_EXISTING_FORM'
                            value='Получить ссылку'>_{GET_THE_LINK}_
                    </button>
                </div>
            </div>
        </div>
    </div>
</form>