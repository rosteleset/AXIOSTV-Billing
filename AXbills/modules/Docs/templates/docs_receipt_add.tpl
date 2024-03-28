<form action='%SELF_URL%' method='post' name='invoice_add'>
    <input type='hidden' name='index' value='%index%'>
    <input type='hidden' name='UID' value='$FORM{UID}'>
    <input type='hidden' name='DOC_ID' value='%DOC_ID%'>
    <input type='hidden' name='sid' value='$FORM{sid}'>
    <input type='hidden' name='step' value='$FORM{step}'>
    <input type='hidden' name='OP_SID' value='%OP_SID%'>
    <input type='hidden' name='VAT' value='%VAT%'>
    <input type='hidden' name='SEND_EMAIL' value='1'>
    <input type='hidden' name='ALL_SERVICES' value='1'>

    <div class='card container-md'>
        <div class='card-header with-border'>
            <h3 class='card-title'>%CAPTION%</h3>
        </div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='DATE'>_{DATE}_:</label>
                <div class='col-sm-12 col-md-9'>
                    <div class='input-group'>
                        %DATE%
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3'
                       for='CURENT_BILLING_PERIOD'>_{CURENT_BILLING_PERIOD}_:</label>
                <div class='col-sm-12 col-md-9'>
                    <div class='input-group'>
                        <input type='text' readonly id='CURENT_BILLING_PERIOD' name='CUSTOMER'
                               value='%CURENT_BILLING_PERIOD_START% - %CURENT_BILLING_PERIOD_STOP%'
                               placeholder='%CUSTOMER%'
                               class='form-control'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='PERIOD'>_{PERIOD}_:</label>
                <div class='col-sm-12 col-md-9'>
                    <div class='input-group'>
                        %PERIOD_DATE%
                    </div>
                </div>
            </div>

            <div class='form-group'>
                <div class='custom-control custom-radio'>
                    <input class='custom-control-input' type='radio' value='0' id='INCLUDE_CUR_BILLING_PERIOD1'
                           name='INCLUDE_CUR_BILLING_PERIOD'>
                    <label for='INCLUDE_CUR_BILLING_PERIOD1'
                           class='custom-control-label'>_{INCLUDE_CUR_BILLING_PERIOD}_ </label>
                </div>
                <div class='custom-control custom-radio'>
                    <input class='custom-control-input' type='radio' value='1' id='INCLUDE_CUR_BILLING_PERIOD2'
                           name='INCLUDE_CUR_BILLING_PERIOD'>
                    <label for='INCLUDE_CUR_BILLING_PERIOD2' class='custom-control-label'>_{NOT_INCLUDE_CUR_BILLING_PERIOD}_</label>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='NEXT_PERIOD'>_{NEXT_PERIODS}_ (_{MONTH}_):</label>
                <div class='col-sm-12 col-md-9'>
                    <div class='input-group'>
                        <input type='text' name='NEXT_PERIOD' ID='NEXT_PERIOD' value='%NEXT_PERIOD=0%' size='5'
                               class='form-control'>
                    </div>
                </div>
            </div>

            <div class='form-group custom-control custom-checkbox'>
                <input class='custom-control-input' type='checkbox' name='SEND_EMAIL' id='SEND_EMAIL'>
                <label for='SEND_EMAIL' class='custom-control-label'>_{SEND}_ E-mail:</label>
            </div>

            <div class='form-group custom-control custom-checkbox'>
                <input class='custom-control-input' type='checkbox' name='INCLUDE_DEPOSIT' id='INCLUDE_DEPOSIT'>
                <label for='INCLUDE_DEPOSIT' class='custom-control-label'>_{INCLUDE_DEPOSIT}_:</label>
            </div>

            <div class='form-group'>
              %ORDERS%
            </div>

        </div>
        <div class='card-footer'>
           %BACK%
           <input type='submit' name='update' value='_{REFRESH}_' class='btn btn-secondary'>
           <input type='submit' name='create' value='_{CREATE}_' class='btn btn-primary'>
           %NEXT%
        </div>
    </div>
</form>
