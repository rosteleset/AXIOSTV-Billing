<form action='%SELF_URL%' method='POST' id='DILLER_SUM_OPERATIONS'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='operations_log' value='1'>

    <div class='card card-primary card-outline'>
        <div class='card-header with-border text-center'>
            <h4>
                _{INFO}_
            </h4>
        </div>
        <div class='panel-body'>
            <div class='table table-hover table-striped'>
                <div class='row'>
                    <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{SUM_OPERATIONS}_:</div>
                    <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%SUM_OPERATIONS%</div>
                </div>
                <div class='row'>
                    <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{PERIOD}_:</div>
                    <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%PERIOD%</div>
                </div>
                <div class='row'>
                    <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{COUNT}_:</div>
                    <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%COUNT%</div>
                </div>
            </div>
        </div>
    </div>
</form>

