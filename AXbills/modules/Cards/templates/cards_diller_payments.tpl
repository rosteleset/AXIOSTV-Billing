<form action='%SELF_URL%' method='POST' class='form-horizontal' id='DILLER_PAYMENTS'>
    <input type='hidden' name='index' value="%INDEX%">
    <input type='hidden' name='diller_payment' value="1">
    <input type='hidden' name='UID' value="%UID%">
    <input type='hidden' name='LOGIN' value="%LOGIN%">

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'><h4 class='card-title'>_{PAYMENTS}_</h4></div>

        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label' for='SUM'>_{SUM}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input class='form-control' id='SUM' type='text' name='SUM' value='%SUM%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label' for='COMMENTS'>_{COMMENTS}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input class='form-control' type='text' id='COMMENTS' name='COMMENTS' value='%COMMENTS%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label'>_{TYPE}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %TYPE_PAYMENT%
                </div>
            </div>
            <input class='btn btn-primary col-md-12 col-sm-12' type='submit' value='_{PAY}_'>
        </div>
    </div>

    <div class='card card-primary card-outline'>
        <div class='card-header with-border text-center'>
            <h4>
                _{INFO}_
            </h4>
        </div>
        <div class='panel-body'>
            <div class='table table-hover table-striped'>
                <div class='row'>
                    <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{LOGIN}_: </div>
                    <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%LOGIN%</div>
                </div>
                <div class='row'>
                    <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{TARIF_PLAN}_:</div>
                    <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%TP_NAME%</div>
                </div>
                <div class='row'>
                    <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{DEPOSIT}_:</div>
                    <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%DEPOSIT%</div>
                </div>
            </div>
        </div>
    </div>
</form>

