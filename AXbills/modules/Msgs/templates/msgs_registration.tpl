<FORM action='$SELF_URL' METHOD='POST' ID='REGISTRATION'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
    <input type='hidden' name='module' value='Msgs'>

    <div class='card center-block container-md'>
        <div class='card-header with-border'>
            <h4 class='card-title'>_{REGISTRATION}_</h4>
        </div>
        <div class='card-body'>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='LOGIN'>_{LOGIN}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='LOGIN' name='LOGIN' value='%LOGIN%' required='required' title='_{SYMBOLS_REG}_a-Z 0-9' placeholder='_{LOGIN}_'
                            class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='FIO'>_{FIO}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='FIO' name='FIO' value='%FIO%' required='required' placeholder='_{FIO}_'
                            class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='PHONE'>_{PHONE}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='PHONE' name='PHONE' value='%PHONE%' required='required' placeholder='_{PHONE}_'
                            class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='EMAIL'>E-MAIL:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='E-mail' class='form-control'
                            type='text'>
                    </div>
                </div>
            </div>

            <hr/>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='CITY'>_{CITY}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='CITY' name='CITY' value='%CITY%' placeholder='_{CITY}_' class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='ZIP'>_{ZIP}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='ZIP' name='ZIP' value='%ZIP%' placeholder='_{ZIP}_' class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='ADDRESS_STREET'>_{ADDRESS_STREET}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='ADDRESS_STREET' name='ADDRESS_STREET' value='%ADDRESS_STREET%'
                            placeholder='_{ADDRESS_STREET}_' class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='ADDRESS_BUILD'>_{ADDRESS_BUILD}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='ADDRESS_BUILD' name='ADDRESS_BUILD' value='%ADDRESS_BUILD%'
                            placeholder='_{ADDRESS_BUILD}_' class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='ADDRESS_FLAT'>_{ADDRESS_FLAT}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input type='text' name='ADDRESS_FLAT' value='%ADDRESS_FLAT%' placeholder='_{ADDRESS_FLAT}_' class='form-control' id='ADDRESS_FLAT'>
                    </div>
                </div>
            </div>

            <hr/>

            %PAYMENTS%

            <div class='form-group row'>
                <label class='control-element col-md-12 text-center' for='TP_ID'>_{RULES}_</label>
                <div class='col-md-12'>
                    <textarea cols='60' rows='8' class='form-control' id='TP_ID'></textarea>
                </div>
            </div>

            <div class='form-group row text-center'>
                <div class='custom-control custom-checkbox'>
                    <input class='custom-control-input' type='checkbox' id='ACCEPT_RULES' required name='ACCEPT_RULES' value='1'>
                    <label for='ACCEPT_RULES' class='custom-control-label'>_{ACCEPT}_</label>
                </div>
            </div>

            %CAPTCHA%

        </div>
        <div class='card-footer'>
            <input type='submit' name='reg' value='_{SEND}_' class='btn btn-primary'>
        </div>

    </div>

</FORM>
