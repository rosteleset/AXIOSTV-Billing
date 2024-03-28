<form method='POST' action='https://api.privatbank.ua:9083/p24api/ishop' class='form form-horizontal'>

<div class='card box-primary'>
    <div class='card-header with-border text-center'><h4 class='card-title'>_{BALANCE_RECHARCHE}_</h4></div>

<div class='card-body'>
    <div class='form-group'>
        <label class='col-md-6 col-sm-6 text-right'>_{ORDER}_:</label>
        <label class='col-md-6 col-sm-6'>$FORM{OPERATION_ID}</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 col-sm-6 text-right'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 col-sm-6 '>Privat Bank - Privat 24</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 col-sm-6 text-right'>_{BALANCE_RECHARCHE_SUM}_:</label>
        <label class='col-md-6 col-sm-6 '> $FORM{SUM} </label>
    </div>
	 <div class='form-group'>
         <label class='col-md-6 col-sm-6 text-right'>_{COMMISSION}_:</label>
        <label class='col-md-6 col-sm-6 '> %COMMISSION_SUM% </label>
    </div>

    <div class='form-group'>
        <label class='col-md-6 col-sm-6 text-right'>_{TOTAL}_ _{SUM}_:</label>
        <label class='col-md-6 col-sm-6 '> $FORM{TOTAL_SUM} </label>
    </div>

<input type='hidden' name='amt' value='$FORM{TOTAL_SUM}' />
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='PAYMENT_SYSTEM' value='54'>
<input type='hidden' name='OPERATION_ID' VALUE='$FORM{OPERATION_ID}'>
<input type='hidden' name='TP_ID' value='$FORM{TP_ID}'>
<input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
<input type='hidden' name='ccy' value='$conf{PAYSYS_P24_MERCHANT_CURRENCY}' />
<input type='hidden' name='merchant' value='$conf{PAYSYS_P24_MERCHANT_ID}' />
<input type='hidden' name='order' value='$FORM{OPERATION_ID}' />
<input type='hidden' name='details' value='%LOGIN% $FORM{DESCRIBE} # $FORM{OPERATION_ID} UID: %UID%'  />
<input type='hidden' name='ext_details' value='%FIO% %CONTRACT_ID% %CONTRACT_DATE%' />
<input type='hidden' name='pay_way' value='privat24' />
<input type='hidden' name='return_url' value='%RETURN_URL%' />

<input type='hidden' name='server_url' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi' />

</div>
    <div class='card-footer'>
        <input class='btn btn-primary' type=submit value='_{PAY}_'>
    </div>
</div>   

<!-- <button type='submit'><img src='https://privat24.privatbank.ua/p24/img/buttons/api_logo_2.jpg' border='0' /></button> -->


</form>
