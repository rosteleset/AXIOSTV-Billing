<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='%ID%'>
    <input type='hidden' name='SERVICE_ID' value='%SERVICE_ID%'>
    <input type='hidden' name='DEV_ID' value='%DEV_ID%'>
    <div class='card card-primary card-outline card-form'>
        <div class='card-header with-border'><h4 class='card-title'>%DEVICE_ACTION%</h4></div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label col-md-3 required' for="DEVICE_ID">_{DEVICE}_: </label>
                <div class='col-md-9'>
                    <input required='' type='text' class='form-control' id="DEVICE_ID" name='DEVICE_ID' value='%DEVICE_ID%'/>
                </div>
            </div>
            <div class='form-group row'>
                <label class='control-label col-md-3'>_{USER}_:</label>
                <div class='col-md-9'>
                    %USERS_LIST%
                </div>
            </div>
            <div class='form-group row'>
                <label class='control-label col-md-3 required' for="IP_ACTIVITY">IP: </label>
                <div class='col-md-9'>
                    <input required='' type='text' class='form-control' id="IP_ACTIVITY" name='IP_ACTIVITY' value='%IP_ACTIVITY%'/>
                </div>
            </div>
            <div class="form-group custom-control custom-checkbox">
                <input class="custom-control-input" type="checkbox" id="ENABLE" name="ENABLE"
                       data-checked='%ENABLE%' value='1'>
                <label for="ENABLE" class="custom-control-label">_{ENABLE}_</label>
            </div>
            <div class='form-group row'>
                <label class='control-label col-md-3' for="CODE">_{CODE}_: </label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' id="CODE" name='CODE' value='%CODE%'/>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
        </div>
    </div>
</form>
