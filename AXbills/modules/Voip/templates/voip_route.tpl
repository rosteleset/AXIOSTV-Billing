<div class='d-print-none'>
    <form action='%SELF_URL%' method='post'>
        <input type=hidden name='index' value='%index%'>
        <input type=hidden name=chg value='%ROUTE_ID%'>
        <input type=hidden name=PARENT_ID value='%PARENT_ID%'>
        <input type=hidden name=ROUTE_ID value='$FORM{ROUTE_ID}'>

        <div class='card card-primary card-outline box-form'>
            <div class='card-header with-border'><h4 class='card-title'>_{ROUTES}_</h4></div>
            <div class='card-body'>
                <div class='form-group row'>
                    <label class='col-md-3 control-label' for='ROUTE_PREFIX'>_{PREFIX}_</label>
                    <div class='col-md-9'>
                        <input class='form-control' id='ROUTE_PREFIX' type=text name=ROUTE_PREFIX value='%ROUTE_PREFIX%'>
                    </div>
                </div>
                <div class='form-group row'>
                    <label class='col-md-3 control-label' for=ROUTE_NAME>_{NAME}_</label>
                    <div class='col-md-9'>
                        <input class='form-control' type=text  id=ROUTE_NAME name=ROUTE_NAME value='%ROUTE_NAME%'>
                    </div>
                </div>
                <div class='form-group row'>
                    <label class='col-md-3 control-label' for='DISABLE'>_{DISABLE}_</label>
                     <div class='col-md-9'>
                         <input type=checkbox name=DISABLE id='DISABLE' value='1' %DISABLE%>
                      </div>
                </div>
                <div class='form-group row'>
                    <label class='col-md-3 control-label' for='DESCRIBE'>_{DESCRIBE}_</label>
                    <div class='col-md-9'>
                        <input class='form-control' type=text id='DESCRIBE' name=DESCRIBE value='%DESCRIBE%'>
                    </div>
                </div>
            </div>
            <div class='card-footer'>
                <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
            </div>
        </div>

    </form>
</div>
