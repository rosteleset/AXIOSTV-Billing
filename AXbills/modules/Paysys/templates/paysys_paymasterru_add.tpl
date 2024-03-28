<div class='card card-primary card-outline'>
    <form action='https://paymaster.ru/Payment/Init' method='POST'>
        <input type='hidden' name='LMI_MERCHANT_ID' value='%LMI_MERCHANT_ID%'>
        <input type='hidden' name='LMI_PAYMENT_AMOUNT' value='%SUM%'>
        <input type='hidden' name='LMI_CURRENCY' value='%CURRENCY%'>
        <input type='hidden' name='LMI_PAYMENT_NO' value='%ORDER_ID%'>
        <input type='hidden' name='LMI_SIM_MODE' value='%SIM_MOD%'>
        <input type='hidden' name='LMI_PAYMENT_DESC' value='Internet'>
        <input type='hidden' name='LMI_PAYMENT_NOTIFICATION_URL' value='%NOTIFICATION_URL%'>
        <input type='hidden' name='LMI_SUCCESS_URL' value='%SUCCESS_URL%'>
        <input type='hidden' name='LMI_FAILURE_URL' value='%FAILURE_URL%'>
        <input type='hidden' name='USER' value='%USER%'>
        <input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].NAME' value='%NAME%'>
        <input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].QTY' value='%QTY%'>
        <input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].PRICE' value='%PRICE%'>
        <input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].TAX' value='%TAX%'>
        <input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].METHOD' value='%METHOD%'>
        <input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].SUBJECT' value='%SUBJECT%'>
        <input type='hidden' name='LMI_PAYER_EMAIL' value='%LMI_PAYER_EMAIL%'>

        <div class='card-header with-border text-center pb-0'>
            <h4>_{BALANCE_RECHARCHE}_</h4>
        </div>
        <div class='card-body pt-0'>
            <div class='form-group text-center'>
                <img src='/styles/default/img/paysys_logo/paymasterru-logo.png'
                     style='width: auto; max-height: 200px;'
                     alt='paymaster RU'>
            </div>


            <ul class='list-group list-group-unbordered mb-3'>
                <li class='list-group-item'>
                    <b>_{DESCRIBE}_</b>
                    <div class='float-right'>$FORM{DESCRIBE}</div>
                </li>
                <li class='list-group-item'>
                    <b>_{ORDER}_</b>
                    <div class='float-right'>%ORDER_ID%</div>
                </li>
                <li class='list-group-item'>
                    <b>_{SUM}_</b>
                    <div class='float-right'>%SUM%</div>
                </li>
                %EXTRA_DESCRIPTIONS%
            </ul>
            <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
        </div>
    </form>
</div>