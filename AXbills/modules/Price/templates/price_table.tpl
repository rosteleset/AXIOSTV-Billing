<script>
    var Sum = 1200;
    var TotalCheckbox = 0;
    var TotalDigit = 0;
    var UserSum = 0;

    function rebuild_form() {
        TotalCheckbox = 0;
        jQuery("[data-price]").each(function () {
            if (jQuery(this).prop("checked")) {
                TotalCheckbox = TotalCheckbox + +jQuery(this).attr("data-price");
            }
            document.getElementById('total_sum').innerHTML = (Sum + TotalCheckbox + TotalDigit)
                + " <span class='fa fa-usd'></span>";
        })

        TotalDigit = 0;
        jQuery("[data-num]").each(function () {
            if (jQuery(this).val() && jQuery(this).val() > 0) {
                TotalDigit = TotalDigit + jQuery(this).val() * jQuery(this).attr("data-num");
            }
            document.getElementById('total_sum').innerHTML = (Sum + TotalCheckbox + TotalDigit)
                + " <span class='fa fa-usd'></span>";
        })
    }

    jQuery(function () {
        rebuild_form();
        getCurrentDate();

        jQuery("[data-price]").change(function () {
            rebuild_form();
        });
        jQuery("[data-num]").on('input',function(e){
            rebuild_form();
        });
    });

    function getUsersSum() {
        var user = document.getElementById("ALL_USERS").value;
        if (user > 1000) {
            if ((user - 1000) < 500 && user != 0) {
                Sum = 100 + 1200;
            }
            else if ((user - 1000) % 500 === 0) {
                Sum = (((user - 1000) / 500 >> 0) * 100) + 1200;
            }
            else if ((user - 1000) % 500 !== 0) {
                Sum = (((user - 1000) / 500 >> 0) * 100) + 100 + 1200;
            }
            UserSum = Sum - 1200;
        }
        else {
            Sum = 1200;
        }

        document.getElementById('user_sum').innerText = "_{PRICE_FOR}_ _{ADDITIONAL_SUBSCRIBERS}_ : " + UserSum;
        document.getElementById('total_sum').innerHTML = (Sum + TotalCheckbox + TotalDigit) + " <span class='fa fa-usd'></span>";
    }

    function getCurrentDate() {
        var today = new Date();
        var dd = today.getDate();

        var mm = today.getMonth() + 1;
        var yyyy = today.getFullYear();
        if (dd < 10) {
            dd = '0' + dd;
        }

        if (mm < 10) {
            mm = '0' + mm;
        }
        today = yyyy+ '-' + mm + '-' + dd;
        document.getElementById('current_date').innerText = 'Дата заполнения: ' + today;

        if (!document.getElementById('CURRENT_D').value) {
            document.getElementById('CURRENT_D').value = today;
        }

    }
</script>

<body onload="getUsersSum()">
<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='ID' value='1'>
    <input type='hidden' name='module' value='Price'>
    <input type='hidden' id='CURRENT_D' name='CURRENT_D' value='%CURRENT_D%'>
    <input type='hidden' name='LINK_FORM' value='%LINK_FORM%'>

    <div class='card container-md'>
        <div class='card-header with-border'>
            <h3 class='card-title'>
                <div class='row'>
                    <div class='col-md-12 col-md-offset-1'>
                        <h2><span class='fa fa-fw fa-wrench'></span>_{PRICE_SUPPORT}_</h2>
                    </div>
                </div>
                <div class='row'>
                    <div class='col-md-12 col-md-offset-1'>
                        <h4 id="current_date" name="CURRENT_DATE">Дата заполения:</h4>
                    </div>
                </div>
            </h3>
        </div>
        <div class="card-body">
            <div class="form-group row">
                <label class="col-sm-4 col-md-3" for="E_MAIL">E-mail:</label>
                <div class="col-sm-8 col-md-7">
                    <div class='input-group'>
                        <input required="" type="email" class="form-control" id="E_MAIL" name="E_MAIL" value="%E_MAIL%">
                    </div>
                </div>
                <button class='col-md-2 btn btn-sm btn-primary' type='submit' formnovalidate name='EMAIL_FORM'
                    id="EMAIL_FORM" value='_{PREVIOUS_FORM}_'>_{PREVIOUS_FORM}_
                </button>
            </div>
        </div>
        <div class="card">
            <div class="card-header with-border">
                <h2 class="card-title">_{GENERAL_INFORMATION}_</h2>
            </div>
            <div class="card-body">
                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="BILLING_SYSTEM">_{BILLING_OPERATION_SYSTEM}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input required="" type="text" class="form-control" name="BILLING_SYSTEM"
                                id="BILLING_SYSTEM" value="%BILLING_SYSTEM%">
                        </div>
                    </div>
                </div>
                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="ALL_USERS">_{NUMBER_OF_USERS}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input required="" type="number" class="form-control" id="ALL_USERS" name="ALL_USERS"
                                value="%ALL_USERS%" onkeyup="getUsersSum()">
                        </div>
                    </div>
                </div>
                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="ONLINE_USERS">_{ONLINE}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input required="" type="number" class="form-control" name="ONLINE_USERS"
                                id="ONLINE_USERS" value="%ONLINE_USERS%">
                        </div>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-xs-10">_{NOTE}_</div>
                </div>
                <div class="form-group">
                    <div class="col-xs-10" id="user_sum">_{PRICE_FOR}_ _{ADDITIONAL_SUBSCRIBERS}_ : 0</div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="SERVER_CONFIG">_{HARDWARE_CONFIGURATION}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <textarea class="form-control" id="SERVER_CONFIG" name="SERVER_CONFIG" rows="3">%SERVER_CONFIG%</textarea>
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="SERVER_NUMBERS">_{ACCESS_SERVERS}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <textarea class="form-control" id="SERVER_NUMBERS" name="SERVER_NUMBERS" rows="3">%SERVER_NUMBERS%</textarea>
                        </div>
                    </div>
                </div>
            </div>
        <br>

        %PANEL%

        <div class="card">
            <div class="card-header with-border">
                <h2 class="card-title">_{SSL_CERTIFICATES}_</h2>
            </div>
            <div class="card-body">
                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="COUNTRY_NAME">_{COUNTRY}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="COUNTRY_NAME" name="COUNTRY_NAME"
                                value="%COUNTRY_NAME%">
                        </div>
                    </div>
                </div>
                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="STATE_NAME">_{STATE_OR_REGION}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="STATE_NAME" name="STATE_NAME"
                                value="%STATE_NAME%">
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="LOCALITY_NAME">_{CITY}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="LOCALITY_NAME" name="LOCALITY_NAME"
                                value="%LOCALITY_NAME%">
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="ORGANIZATION_NAME">_{ORGANIZATION_NAME}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="ORGANIZATION_NAME" name="ORGANIZATION_NAME"
                                value="%ORGANIZATION_NAME%">
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="ORGANIZATION_UNIT_NAME">_{ORGANIZATION_UNIT_NAME}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="ORGANIZATION_UNIT_NAME"
                                name="ORGANIZATION_UNIT_NAME"
                                value="%ORGANIZATION_UNIT_NAME%">
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="E_MAIL_ADDRESS">_{EMAIL_RESPONSIBLE}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="E_MAIL_ADDRESS" name="E_MAIL_ADDRESS"
                                value="%E_MAIL_ADDRESS%">
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="COMMON_NAME">Common name:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="COMMON_NAME" name="COMMON_NAME"
                                value="%COMMON_NAME%">
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="WEB_ADDRESS">_{WEB_ADDRESS}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="WEB_ADDRESS" name="WEB_ADDRESS"
                                value="%WEB_ADDRESS%">
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="SERVER_ADDRESS_EMAIL">_{MAIL_SERVER_ADDRESS}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="SERVER_ADDRESS_EMAIL"
                                name="SERVER_ADDRESS_EMAIL"
                                value="%SERVER_ADDRESS_EMAIL%">
                        </div>
                    </div>
                </div>

                <div class="form-group row">
                    <label class="col-sm-4 col-md-3" for="SERVER_ADDRESS">_{ACCESS_SERVER_ADDRESS}_:</label>
                    <div class="col-sm-8 col-md-7">
                        <div class='input-group'>
                            <input type="text" class="form-control" id="SERVER_ADDRESS" name="SERVER_ADDRESS"
                                value="%SERVER_ADDRESS%">
                        </div>
                    </div>
                </div>
            </div>
        </div>

            <div class="card">
                <div class="card-header with-border">
                    <h2 class="card-title">_{ORGANIZATION_INFORMATION}_</h2>
                </div>
                <div class="card-body">
                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="COMPANY_NAME">_{ORGANIZATION_NAME}_:</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <input type="text" class="form-control" id="COMPANY_NAME" name="COMPANY_NAME"
                                    value="%COMPANY_NAME%">
                            </div>
                        </div>
                    </div>

                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="LEGAL_ADDRESS">_{LEGAL_ADDRESS}_:</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <input type="text" class="form-control" id="LEGAL_ADDRESS" name="LEGAL_ADDRESS"
                                    value="%LEGAL_ADDRESS%">
                            </div>
                        </div>
                    </div>

                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="CONTACT_INFO">_{CONTACT_INFORMATION}_ (E-Mail, Skype, Viber, WhatsApp):</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <textarea class="form-control" id="CONTACT_INFO" name="CONTACT_INFO"
                                    rows="3">%CONTACT_INFO%</textarea>
                            </div>
                        </div>
                    </div>

                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="TARYF">_{DESC_OF_TARIFF_PLANS}_:</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <textarea class="form-control" id="TARYF" name="TARYF" rows="3">%TARYF%</textarea>
                            </div>
                        </div>
                    </div>

                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="ADD_INFO">_{ADDITIONALLY}_:</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <textarea class="form-control" id="ADD_INFO" name="ADD_INFO" rows="3">%ADD_INFO%</textarea>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <br>

            <div class="card">
                <div class="card-header with-border">
                    <h2 class="card-title">_{INFORMATION_FOR_ACCESS}_:</h2>
                </div>
                <div class="card-body">
                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="IP_ADDRESS">IP:</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <input type="text" class="form-control" id="IP_ADDRESS" name="IP_ADDRESS"
                                    value="%IP_ADDRESS%">
                            </div>
                        </div>
                    </div>
                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="LOGIN_INFO">Login:</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <input type="text" class="form-control" id="LOGIN_INFO" name="LOGIN_INFO"
                                    value="%LOGIN_INFO%">
                            </div>
                        </div>
                    </div>
                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="PASSWORD_INFO">Password:</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <input type="text" class="form-control" name="PASSWORD_INFO" id="PASSWORD_INFO"
                                    value="%PASSWORD_INFO%">
                            </div>
                        </div>
                    </div>
                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="ROOT_PASSWORD">_{SUPERUSER_PASSWORD}_ (root):</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <input type="text" class="form-control" name="ROOT_PASSWORD" id="ROOT_PASSWORD"
                                    value="%ROOT_PASSWORD%">
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <br>

            <div class="card">
                <div class="card-header with-border">
                    <h2 class="card-title">_{ADDITIONAL_INFORMATION}_:</h2>
                </div>
                <div class="card-body">
                    <div class="form-group row">
                        <label class="col-sm-4 col-md-3" for="COMMENTS">_{ADDITIONAL_INFORMATION}_:</label>
                        <div class="col-sm-8 col-md-7">
                            <div class='input-group'>
                                <textarea class="form-control" id="COMMENTS" name="COMMENTS" rows="3">%COMMENTS%</textarea>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class='card-footer'>
                <div class="form-group row">
                    <div class='col-md-6'>
                        <button class='btn btn-block btn-primary' type=submit name='ACCEPT' value='_{CONFIRM}_'>
                            _{CONFIRM}_<span class='fa fa-check'></span></button>
                    </div>
                    <div class='col-md-6'>
                        <button class='btn btn-block btn-primary' type=submit formnovalidate name='RES'
                                value='_{RESET}_'>_{RESET}_<span class='fas fa-sync'></span></button>
                    </div>
                </div>
            </div>
        </div>
        <div id='menu'>
            <h4>_{TOTAL}_:</h4>
            <h4 id="total_sum">0<span class='fa fa-usd'></span></h4>
        </div>
    </div>
</form>
</body>

<style>
    #menu {
        position: fixed;
        right: 0;
        top: 50%;
        width: 8em;
        margin: -2.5em 0 0 0;
        z-index: 5;
        background: hsla(0, 0%, 100%, 0.7);
        color: black;
        font-weight: bold;
        font-size: large;
        text-align: left;
        border: solid hsla(192, 100%, 47%, 0.8);
        border-right: none;
        padding: 0.5em 0.5em 0.5em 2.5em;
        box-shadow: 0 1px 3px black;
        border-radius: 3em 0.5em 0.5em 3em;
    }
</style>
