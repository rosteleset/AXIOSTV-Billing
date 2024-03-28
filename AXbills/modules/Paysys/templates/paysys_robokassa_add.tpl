<div class='card card-primary card-outline'>
    <form action='https://auth.robokassa.ru/Merchant/Index.aspx' method=POST>
        <input type=hidden name=MerchantLogin value='%RK_MERCH_LOGIN%'>
        <input type=hidden name=OutSum value='%SUM%'>
        <input type=hidden name=InvId value='%ORDER_ID%'>
        <input type=hidden name=Description value='%DESCRIPTION%'>
        <input type=hidden name=SignatureValue value='%SIGNATURE%'>
        <input type=hidden name=shp_Id value='%shp_Id%'>
        <input type=hidden name=IncCurrLabel value='%CURRENCY%'>
        <input type=hidden name=Culture value='%LANGUAGE%'>
        <input type=hidden name=Encoding value='%ENCODE%'>
        <input type=hidden name=IsTest value='%TEST_MODE%'>

        <div class='card-header with-border text-center pb-0'>
            <h4>_{BALANCE_RECHARCHE}_</h4>
        </div>
        <div class='card-body pt-0'>
            <div class='form-group text-center'>
                <img src='/styles/default/img/paysys_logo/robokassa-logo.png'
                     style='width: auto; max-height: 200px;'
                     alt='robokassa'>
            </div>

            <ul class='list-group list-group-unbordered mb-3'>
                <li class='list-group-item'>
                    <b>_{DESCRIBE}_</b>
                    <div class='float-right'>$FORM{DESCRIBE}</div>
                </li>
                <li class='list-group-item'>
                    <b>_{ORDER}_</b>
                    <div class='float-right'>$FORM{OPERATION_ID}</div>
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