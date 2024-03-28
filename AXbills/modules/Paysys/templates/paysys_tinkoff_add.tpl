<form action='$SELF_URL' method='post'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'/>
    <input type='hidden' name='SUM' value='%SUM%'/>
    <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'/>
    
<div class='card box-primary'>
    <div class='card-header with-border text-center'>Tinkoff: _{BALANCE_RECHARCHE}_</div>

<div class='card-body'>
    <div class='form-group row'>
        <label class='col-md-6 control-label'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>%OPERATION_ID%</label>
    </div>
    
    <div class='form-group row'>
        <label class='col-md-6 control-label'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>Tinkoff Bank</label>
    </div>
    
    <div class='form-group row'>
        <label class='control-label col-md-6'>_{SUM}_:</label>
        <label class='control-label col-md-6'> %SUM% </label>
    </div>

    <div class='form-group row'>
        <label class='control-label col-md-6'>_{PERIODIC_PAY}_:</label>
        <label class='control-label col-md-6'>_{ONCE_PER_MONTH}_</label>
    </div>
    <div class='form-group row'>
        <label class='control-label col-md-6' for='RECURRENT'>_{SUBSCRIBE_ACTION}_:</label>
        <div class='col-md-6'>
            %SUBSCRIBE_BTN%
        </div>
        <div class='help-block offset-3'>
            <small class='text-muted' >_{TINKOF_AUTO_OFFER}_<a href='%TINKOF_AUTO_OFFER_URL%'>_{TINKOF_AUTO_OFFER_URL}_</a></small>
        </div>
    </div>
</div>
    <div class='card-footer'>
        <input class='btn btn-primary' type='submit' value='_{PAY}_' name='Init'>
        <small class='text-muted' >_{TINKOF_OFFER}_<a href='%TINKOF_OFFER_URL%'>_{TINKOF_OFFER_URL}_</a></small>
    </div>
</div> 

</form>