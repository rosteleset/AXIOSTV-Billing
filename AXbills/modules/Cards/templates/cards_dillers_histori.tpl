<form action='%SELF_URL%' method='POST' id='DILLER_HISTORIA'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='SERIA' value=''>
    <input type='hidden' name='UID' value=''>

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'>
            <h4 class='card-title'>_{LOG}_</h4>
        </div>
        <div class='card-body'>

            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label'>_{PERIOD}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %DATA_PICER%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label'>_{ICARDS}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %CARD_SELECT%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label'>_{STATUS}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %STATUS_SELECT%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label'>_{ROWS}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input type='text' name='PAGE_ROWS' value='%PAGE_ROWS%' class='form-control'>
                </div>
            </div>
            <input class='btn btn-primary col-md-12 col-sm-12' type='submit' value='_{SEARCH}_'>
        </div>
    </div>
</form>

