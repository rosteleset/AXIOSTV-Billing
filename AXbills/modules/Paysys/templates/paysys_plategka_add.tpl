<form action='https://test.plategka.com/gateway/' method='post'>
    <input type='hidden' name='merchant_id' value='%MERCHANT_ID%'/>
    <input type='hidden' name='order_id' value='%OPERATION_ID%'/>
    <input type='hidden' name='amount' value='%SUM_FOR_PLATEGKA%'/>
    <input type='hidden' name='date' value='%DATE_TIME%'/>
    <input type='hidden' name='description' value='%DESCRIPTION%'/>
    <input type='hidden' name='sd' value='%SD%'/>
    <input type='hidden' name='billers' value='%BILLERS%'/>
    <input type='hidden' name='version' value='4'/>
    <input type='hidden' name='signature' value='%SIGNATURE%'/>


    <div class='card box-primary'>
        <div class='card-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

        <div class='card-body'>
            <div class='form-group'>
                <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
                <label class='col-md-6 control-label'>%OPERATION_ID%</label>
            </div>

            <div class='form-group'>
                <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
                <label class='col-md-6 control-label'>Plategka</label>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
                <label class='control-label col-md-6'>%SUM%</label>
            </div>
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type='submit' value=_{PAY}_ name='pay'>
        </div>
    </div>

</form>