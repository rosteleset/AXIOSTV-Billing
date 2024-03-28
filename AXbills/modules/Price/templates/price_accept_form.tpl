<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='CECKED_MAS_NAME' value='%MAS%'>
    <input type='hidden' name='CECKED_SUMM_NAME' value='%SUMM%'>
    <input type='hidden' id='CURRENT_D' name='CURRENT_D' value='%CURRENT_D%'>
    <input type='hidden' name='module' value='Price'>
    <input type='hidden' name='LINK_FORM' value='%LINK_FORM%'>


    <div class='card box-primary'>
        <div class='card-header with-border'>
            <h3 class='card-title'>
                <div class='row'>
                    <div class='col-md-12 col-md-offset-1'>
                        <h2><span class='fa fa-fw fa-wrench'></span>_{PRICE_SUPPORT}_</h2>
                    </div>
                </div>
            </h3>
            <div class='card-tools'>
                <h3 id="total_sum"><strong>_{TOTAL}_: %SUMM%<span class='fa fa-usd'></span></strong></h3>
            </div>
        </div>
        <div class="card-body">
            <div class="form-group">
                <label class="col-md-1 control-element" for="E_MAIL">E-mail:</label>
                <div class="col-md-3">
                    <input required="" type="email" class="form-control" id="E_MAIL" name="E_MAIL" value="%E_MAIL%">
                </div>
                <div class='col-md-2'>
                    <button class='btn btn-block btn-primary' type='submit' name='EMAIL_FORM'
                            value='Предыдущая форма'>_{PREVIOUS_FORM}_
                    </button>
                </div>
            </div>
        </div>
        <div class="container">
            <div class="card box-info ">
                <div class="card-header with-border">
                    <h2 class="card-title">_{GENERAL_INFORMATION}_</h2>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label class="col-md-3 control-element"
                               for="BILLING_SYSTEM">_{BILLING_OPERATION_SYSTEM}_:</label>
                        <div class="col-md-6">
                            <input required="" type="text" class="form-control" id="BILLING_SYSTEM"
                                   name="BILLING_SYSTEM" value="%BILLING_SYSTEM%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element">_{NUMBER_OF_USERS}_:</label>
                        <label class="col-md-1 control-element" for="ALL_USERS">_{TOTAL}_:</label>
                        <div class="col-md-2">
                            <input required="" type="number" class="form-control" id="ALL_USERS" name="ALL_USERS"
                                   value="%ALL_USERS%" readonly>
                        </div>
                        <label class="col-md-1 control-element" for="ONLINE_USERS">_{ONLINE}_:</label>
                        <div class="col-md-2">
                            <input required="" type="number" class="form-control" name="ONLINE_USERS" id="ONLINE_USERS"
                                   value="%ONLINE_USERS%" readonly>
                        </div>
                        <div class="col-xs-10">%SECOND_PANEL%</div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="SERVER_CONFIG">_{HARDWARE_CONFIGURATION}_:</label>
                        <div class="col-md-6">
                            <textarea class="form-control" id="SERVER_CONFIG" name="SERVER_CONFIG" rows="3"
                                      readonly>%SERVER_CONFIG%</textarea>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="SERVER_NUMBERS">_{ACCESS_SERVERS}_:</label>
                        <div class="col-md-6">
                            <textarea class="form-control" id="SERVER_NUMBERS" name="SERVER_NUMBERS" rows="3"
                                      readonly>%SERVER_NUMBERS%</textarea>
                        </div>
                    </div>
                </div>
            </div>
            <br>

            %PANEL%

            <div class="card box-info ">
                <div class="card-header with-border">
                    <h2 class="card-title">_{SSL_CERTIFICATES}_</h2>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="COUNTRY_NAME">_{COUNTRY}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="COUNTRY_NAME" name="COUNTRY_NAME"
                                   value="%COUNTRY_NAME%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="STATE_NAME">_{STATE_OR_REGION}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="STATE_NAME" name="STATE_NAME"
                                   value="%STATE_NAME%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="LOCALITY_NAME">_{CITY}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="LOCALITY_NAME" name="LOCALITY_NAME"
                                   value="%LOCALITY_NAME%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="ORGANIZATION_NAME">_{ORGANIZATION_NAME}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="ORGANIZATION_NAME" name="ORGANIZATION_NAME"
                                   value="%ORGANIZATION_NAME%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element"
                               for="ORGANIZATION_UNIT_NAME">_{ORGANIZATION_UNIT_NAME}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="ORGANIZATION_UNIT_NAME"
                                   name="ORGANIZATION_UNIT_NAME"
                                   value="%ORGANIZATION_UNIT_NAME%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="E_MAIL_ADDRESS">_{EMAIL_RESPONSIBLE}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="E_MAIL_ADDRESS" name="E_MAIL_ADDRESS"
                                   value="%E_MAIL_ADDRESS%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="COMMON_NAME">Common name:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="COMMON_NAME" name="COMMON_NAME"
                                   value="%COMMON_NAME%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="WEB_ADDRESS">_{WEB_ADDRESS}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="WEB_ADDRESS" name="WEB_ADDRESS"
                                   value="%WEB_ADDRESS%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element"
                               for="SERVER_ADDRESS_EMAIL">_{MAIL_SERVER_ADDRESS}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="SERVER_ADDRESS_EMAIL"
                                   name="SERVER_ADDRESS_EMAIL" value="%SERVER_ADDRESS_EMAIL%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="SERVER_ADDRESS">_{ACCESS_SERVER_ADDRESS}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="SERVER_ADDRESS" name="SERVER_ADDRESS"
                                   value="%SERVER_ADDRESS%" readonly>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card box-info ">
                <div class="card-header with-border">
                    <h2 class="card-title">_{ORGANIZATION_INFORMATION}_</h2>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="COMPANY_NAME">_{ORGANIZATION_NAME}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" name="COMPANY_NAME" id="COMPANY_NAME"
                                   value="%COMPANY_NAME%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="LEGAL_ADDRESS">_{LEGAL_ADDRESS}_:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" name="LEGAL_ADDRESS" id="LEGAL_ADDRESS"
                                   value="%LEGAL_ADDRESS%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="CONTACT_INFO">_{CONTACT_INFORMATION}_ (E-Mail,
                            Skype, Viber,
                            WhatsApp):</label>
                        <div class="col-md-6">
                            <textarea class="form-control" id="CONTACT_INFO" name="CONTACT_INFO" rows="3"
                                      readonly>%CONTACT_INFO%</textarea>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="TARYF">_{DESC_OF_TARIFF_PLANS}_:</label>
                        <div class="col-md-6">
                            <textarea class="form-control" id="TARYF" name="TARYF" rows="3" readonly>%TARYF%</textarea>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="ADD_INFO">_{ADDITIONALLY}_:</label>
                        <div class="col-md-6">
                            <textarea class="form-control" id="ADD_INFO" name="ADD_INFO" rows="3"
                                      readonly>%ADD_INFO%</textarea>
                        </div>
                    </div>
                </div>
            </div>
            <br>

            <div class="card box-info ">
                <div class="card-header with-border">
                    <h2 class="card-title">_{INFORMATION_FOR_ACCESS}_:</h2>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="IP_ADDRESS">IP:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" name="IP_ADDRESS" value="%IP_ADDRESS%"
                                   id="IP_ADDRESS" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="LOGIN_INFO">Login:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" name="LOGIN_INFO" value="%LOGIN_INFO%"
                                   id="LOGIN_INFO" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="PASSWORD_INFO">Password:</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" name="PASSWORD_INFO" id="PASSWORD_INFO"
                                   value="%PASSWORD_INFO%" readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="ROOT_PASSWORD">_{SUPERUSER_PASSWORD}_
                            (root):</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" name="ROOT_PASSWORD" id="ROOT_PASSWORD"
                                   value="%ROOT_PASSWORD%" readonly>
                        </div>
                    </div>
                    <br>
                </div>
            </div>
            <div class="card box-info ">
                <div class="card-header with-border">
                    <h2 class="card-title">_{ADDITIONAL_INFORMATION}_:</h2>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="PAYMENT_SYS">_{PAYMENT_SYSTEM}_:</label>
                        <div class="col-md-9">
                            <textarea class="form-control" id="PAYMENT_SYS" name="PAYMENT_SYS" rows="3"
                                      readonly>%PAYMENT_SYS%</textarea>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-3 control-element" for="COMMENTS">_{ADDITIONAL_INFORMATION}_:</label>
                        <div class="col-md-9">
                            <textarea class="form-control" id="COMMENTS" name="COMMENTS" rows="3"
                                      readonly>%COMMENTS%</textarea>
                        </div>
                    </div>
                </div>
            </div>
            <div class='card-footer'>
                <row>
                    <div class='col-md-3'>
                        <button class='btn btn-block btn-primary' type='submit' value='_{CANCEL}_'>_{CANCEL}_</button>
                    </div>
                    <div class='col-md-3'>
                        <button class='btn btn-block btn-primary' type='submit' name='MAIL_SEND' value='_{SEND_TO_ADMIN}_'>
                            _{SEND_TO_ADMIN}_
                        </button>
                    </div>
                </row>
            </div>
        </div>
    </div>
</form>


