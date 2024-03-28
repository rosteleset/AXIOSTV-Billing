<form action='$SELF_URL' method='post'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'/>
    <input type='hidden' name='SUM' value='%SUM%'/>
    <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'/>

    <div class='card box-primary'>
        <div class='card-header with-border text-center'>Authorize: _{BALANCE_RECHARCHE}_</div>

        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-6 control-label'>_{ORDER}_:</label>
                <label class='col-md-6 control-label'>%OPERATION_ID%</label>
            </div>

            <div class='form-group row'>
                <label class='col-md-6 control-label'> _{PAY_SYSTEM}_:</label>
                <label class='col-md-6 control-label'>Authorize</label>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-6'>_{SUM}_:</label>
                <label class='control-label col-md-6'> %SUM% </label>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-6'>_{CARD_NUMBER}_:</label>
                <input type='text' pattern='[0-9]{13,16}' placeholder='4111111111111111'
                       class='form-control col-md-6' required name='CARD_NUMBER' value='%CARD_NUMBER%'>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-6'>_{DATE}_:</label>
                <input type='text' pattern='[0-9]{4}-[0-1][0-9]' placeholder='2025-05'
                       class='form-control col-md-6' required name='CARD_DATE' value='%CARD_DATE%'>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-6'>CVV:</label>
                <input type='text' pattern='[0-9][0-9][0-9]' placeholder='123'
                       class='form-control  col-md-6' required name='CVV' value='%CVV%'>
            </div>

        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type='submit' value='_{PAY}_' name='Init'>
        </div>
    </div>

</form>