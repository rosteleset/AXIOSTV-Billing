<form action='%YANDEX_ACTION%' method='post'>
    <input type='hidden' name='shopId'         value='%SHOP_ID%'  />
    <input type='hidden' name='scid'           value='%SCID%'     />
    <input type='hidden' name='sum'            value='$FORM{SUM}' />
    <input type='hidden' name='orderNumber'    value='$FORM{OPERATION_ID}' />
    <input type='hidden' name='customerNumber' value='%CUSTOMER%' />
    <input type='hidden' name='paymentType'    value=''           />
    <input type='hidden' name='REGISTRATION_ONLY'    value='%REGISTRATION_ONLY%'           />
    <input type='hidden' name='shopSuccessURL'     value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1&index=$index&PAYMENT_SYSTEM=117&OPERATION_ID=$FORM{OPERATION_ID}&TP_ID=$FORM{TP_ID}&DOMAIN_ID=$FORM{DOMAIN_ID}%SUS_URL_PARAMS%' />
    <input type='hidden' name='shopFailURL'      value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&index=$index&PAYMENT_SYSTEM=117&OPERATION_ID=$FORM{OPERATION_ID}&TP_ID=$FORM{TP_ID}&DOMAIN_ID=$FORM{DOMAIN_ID}%SUS_URL_PARAMS%' />
    <!-- <input name='orderNumber' value='abc1111111' type='hidden'/>
    <input name='cps_phone' value='79110000000' type='hidden'/>
    <input name='cps_email' value='user@domain.com' type='hidden'/>
    <input type='submit' value='Заплатить'/> -->

<div class='card box-primary box-form'>
    <div class='card-header with-border'><h4>_{BALANCE_RECHARCHE}_</h4></div>

<div class='card-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-right'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-right'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>Yandex Kassa</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-right'>_{SUM}_:</label>
        <label class='control-label col-md-6'> $FORM{SUM} </label>
    </div>
</div>
    <div class='card-footer'>
        <input class='btn btn-primary' type=submit value=_{PAY}_>
    </div>
</div> 

</form>