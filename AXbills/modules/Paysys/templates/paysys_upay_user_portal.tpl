<div class='card card-primary card-outline'>
    <form action='https://pay.smst.uz/prePay.do' target='_blank' method='POST'>
        <input type='hidden' name='personalAccount' value='%PERSONAL_ACCOUNT%'>
        <input type='hidden' name='apiVersion' value='1'>
        <input type='hidden' name='serviceId' value='$conf{PAYSYS_UPAY_SERVICE_ID}'>
        <input type='hidden' name='amount' value='%AMOUNT%'>

        <div class='card-header with-border text-center'>
            <h4>_{BALANCE_RECHARCHE}_</h4>
        </div>
        <div class='card-body'>
            <div class='form-group text-center'>
                <img src='/styles/default/img/paysys_logo/upay-logo.png'
                     style='width: auto; max-height: 200px;'
                     alt='upay'>
            </div>

            <table style='min-width:350px;' width='auto'>
                <tr>
                    <td>_{PAY_SYSTEM}_:</td>
                    <td>Upay</td>
                </tr>
                <tr>
                    <td>_{ORDER}_:</td>
                    <td>$FORM{OPERATION_ID}</td>
                </tr>
                <tr>
                    <td>_{SUM}_:</td>
                    <td>$FORM{SUM}</td>
                </tr>
                <tr>
                    <td>_{DESCRIBE}_:</td>
                    <td>$FORM{DESCRIBE}</td>
                </tr>
            </table>

        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type='submit' name='pay' value='Оплатить через UPAY'>
        </div>
    </form>
</div>