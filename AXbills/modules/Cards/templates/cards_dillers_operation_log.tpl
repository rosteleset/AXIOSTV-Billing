<form action='$SELF_URL' method='POST' class='form-horizontal' id='DILLER_OPERATION_LOG'>
    <input type='hidden' name='index' value="%INDEX%">
    <input type='hidden' name='sid' value="%SID%">
    <input type='hidden' name='operations_log' value="1">

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'><h4 class='card-title'>_{LIST_OF_LOGS}_</h4></div>

        <div class='card-body'>
            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-label'>_{PERIOD}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %PERIOD%
                </div>
            </div>
            <input class='btn btn-primary col-md-12 col-sm-12' type='submit' value='_{SEARCH}_'>
        </div>
    </div>
</form>

