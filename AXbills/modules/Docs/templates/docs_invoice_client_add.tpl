<p>
    <a class='btn btn-primary' title='_{NEXT_PERIOD}_ _{INVOICE}_'
    href='$SELF_URL?index=$index&ALL_SERVICES=1&UID=%UID%'>_{NEXT_PERIOD}_ _{INVOICE}_</a>
</p>

<form action='$SELF_URL' method='post' name='invoice_add'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='UID' value='%UID%'>
    <input type='hidden' name='DOC_ID' value='%DOC_ID%'>
    <input type='hidden' name='sid' value='$FORM{sid}'>
    <input type='hidden' name='OP_SID' value='%OP_SID%'>
    <input type='hidden' name='step' value='$FORM{step}'>
    <input type='hidden' name='VAT' value='%VAT%'>
    <input type='hidden' name='SEND_EMAIL' value='1'>
    <input type='hidden' name='INCLUDE_DEPOSIT' value='1'>

    <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
            <h4 class='card-title'>%CAPTION%</h4>
        </div>
        <div class='card-body'>
            %FORM_ACCT_ID%
            <div class='form-group row'>
                <label class='col-sm-4 col-md-4 control-label'>_{DATE}_:</label>
                <div class='col-sm-8 col-md-8'>
                    %DATE_FIELD%
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4 control-label' for='PHONE'>_{PHONE}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <input type='text' name='PHONE' id='PHONE' value='%PHONE%' class='form-control'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4 control-label' for='CUSTOMER'>_{CUSTOMER}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <input type='text' name='CUSTOMER' id='CUSTOMER' value='%CUSTOMER%' class='form-control'>
                </div>
            </div>
            %ORDERS%
        </div>
        <div class='card-footer'>
            <input type=submit name=create value='_{CREATE}_' class='btn btn-primary'>
        </div>
    </div>

</form>
