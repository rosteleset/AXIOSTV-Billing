<form id='liqpay_form' method='post' action='$SELF_URL' accept-charset='utf-8'>
    <input type='hidden' name='index' value='%index%'>
    <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
    <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'>
    <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'>
    <input type='hidden' name='SUM' value='%SUM%'>
    <input type='hidden' name='TOTAL_SUM' value='%TOTAL_SUM%'>
    <input type='hidden' name='PHONE' value='%PHONE%'>
    <input type='hidden' name='SUBSCRIBE' value='1'>
    <input type='hidden' name='SUBSCRIBE_DATE_START' value='%SUBSCRIBE_DATE_START%'>
    <input type='hidden' name='CHECKBOX' value='1'>
    %BODY%
    <div class='container-fluid'>
        <div class='box box-primary'>
            <div class='box-header with-border text-center'>_{SUBSCRIBE_LIQPAY}_</div>
            <div class='box-body'>
                <div class='form-group'>
                    <img class='col-xs-8 col-xs-offset-2' src='https://www.liqpay.ua/static/img/logo.png' />
                </div>
                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label'>_{SUBSCRIBE_ACTION}_:</label>
                    <label class='font-weight-bold col-md-6 form-control-label'>
                        <input type='checkbox' checked ='toggle' class='pull-left text-muted' data-return='1' name='SUBSCRIBE'
                               value='1'/>
                    </label>
                </div>
                <div class='row'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label'></label>
                    <div class='font-weight-bold text-center col-md-6 form-control-label'>
                            <label> _{SUBSCRIBE_DETAILS}_
                                <a href='https://www.liqpay.ua/ru'>_{READ_HERE}_</a>
                            </label>
                    </div>
                </div>
            </div>
            <div class='box-footer'>
                <input class='btn btn-primary center-block' type='submit' value='_{PAY}_' name='cancel_button'>
            </div>

        </div>
    </div>
</form>
