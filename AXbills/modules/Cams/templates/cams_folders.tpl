<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='%ID%'>
    <input type='hidden' name='PARENT_ID' value='%PARENT_ID%'>
    <input type='hidden' name='GROUP_ID_SELECTED' value='%GROUP_ID_SELECTED%'>
    <div class='card card-primary card-outline card-form'>
        <div class='card-header with-border'>
            <h4 class='card-title'>_{CAMERAS}_: _{FOLDER}_</h4>
        </div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label col-md-3 required'>_{SERVICE}_:</label>
                <div class='col-md-9'>
                    %SERVICES_SELECT%
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3 required'>_{GROUP}_:</label>
                <div class='col-md-9'>
                    %GROUP_SELECT%
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3' for="TITLE">_{NAME}_:</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' id="TITLE" name='TITLE' value='%TITLE%'/>
                </div>
            </div>

            <div class='form-group row'>
                <div class='col-md-1'></div>
                <div class='col-md-11'>%ADDRESS%</div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3' for="COMMENT">_{COMMENTS}_:</label>
                <div class='col-md-9'>
                    <textarea class='form-control' rows='5' id="COMMENT" name='COMMENT'>%COMMENT%</textarea>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
        </div>
    </div>
</form>

<script>
    var group_select = document.getElementById("GROUP_ID");
    group_select.textContent = "";
    group_select.value = "";

    autoReload();

    if ('%PARENT_ID%' && '%PARENT_ID%' !== '0') {
        jQuery("#GROUP_ID").prop("disabled", true);
        jQuery("#SERVICE_ID").prop("disabled", true);
    }

    function autoReload() {
        var services = document.getElementById("SERVICE_ID");
        var result = services.value;
        let groupSelected = '%GROUP_ID_SELECTED%' || 0;
        jQuery.post('$SELF_URL', 'header=2&get_index=cams_get_service_groups&SERVICE_ID=' + result + '&GROUP_ID=' + groupSelected, function (data) {
            group_select.textContent = "";
            group_select.value = "";
            group_select.innerHTML = data;
        });
    }
</script>
