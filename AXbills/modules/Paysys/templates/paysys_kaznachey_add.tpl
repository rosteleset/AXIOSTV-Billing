<form method='post' action='' class='form form-horizontal'>
    <input type='hidden' name='action' value='create_payment'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='PAYMENT_SYSTEM' value='104'>
    <input type='hidden' name='SUM' value='$FORM{SUM}'>
    <input type='hidden' name='OID' value='$FORM{OPERATION_ID}'>
    
<div class='card box-primary'>
    <div class='card-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>
    
<div class='card-body'>
    <div class='form-group'>
        <label class='col-md-3 control-label'>_{ORDER}_:</label>
        <label class='col-md-3 control-label'>$FORM{OPERATION_ID}</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-3 control-label'>_{PAY_SYSTEM}_:</label>
        <div class='col-md-9 '>
            <select class='form-control' name='SelectedPaySystemId'>
                %PAYSYSTEMS%
            </select>
        </div>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-3'>_{SUM}_:</label>
        <label class='control-label col-md-3'> %SUMMA% </label>
    </div>
</div>   
    <div class='card-footer'>
        <input class='btn btn-primary' type='submit' value=_{PAY}_>
    </div>
</div>    
</form>


