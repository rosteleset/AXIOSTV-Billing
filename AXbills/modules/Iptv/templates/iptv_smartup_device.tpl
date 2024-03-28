<form method='GET' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='%INDEX%'>
    <!--<input type='hidden' name='chg_device' value='1'>-->
    <input type='hidden' name='chg' value='%CHG%'>
    <input type='hidden' name='UID' value='%UID%'>
    <input type='hidden' name='MODULE' value='%MODULE%'>
    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'><h4>_{CHOOSE}_ _{DEVICE}_</h4></div>
        <div class='card-body'>
            <div class='form-group'>
                %SELECT_DEVICE%
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='select_device' value="_{CHOOSE}_">
        </div>
    </div>
</form>

<form method='GET' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='%INDEX%'>
    <!--<input type='hidden' name='chg_device' value='1'>-->
    <input type='hidden' name='chg' value='%CHG%'>
    <input type='hidden' name='UID' value='%UID%'>
    <input type='hidden' name='MODULE' value='%MODULE%'>
    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'><h4>_{ADD}_ _{DEVICE}_</h4></div>
        <div class='card-body'>
            <div class='form-group'>
                <label class='control-label col-md-4 required' for="DEVICE_ID">_{DEVICE}_ Id: </label>
                <div class='col-md-8'>
                    <input required='' type='text' class='form-control' id="DEVICE_ID" name='DEVICE_ID' value='%DEVICE_ID%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 required' for="IP_ACTIVITY">IP: </label>
                <div class='col-md-8'>
                    <input required='' type='text' class='form-control' id="IP_ACTIVITY" name='IP_ACTIVITY' value='%IP_ACTIVITY%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4' for="ENABLE">_{ENABLE}_ : </label>
                <div class='col-md-8'>
                    <input type='checkbox' class='plugin_checkbox' id="ENABLE" name='ENABLE' value=''/>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='add_device' value="_{ADD}_">
        </div>
    </div>
</form>