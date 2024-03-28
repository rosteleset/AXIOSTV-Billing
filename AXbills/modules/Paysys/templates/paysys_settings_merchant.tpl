<form name='PAYSYS_SETTINGS_MERCHANT' id='form_PAYSYS_SETTINGS_MERCHANT' method='post' class='form form-horizontal %AJAX_SUBMIT_FORM%'>

    <input type='hidden' name='MODULE' value='%PAYSYSTEM_NAME%'>
    <input type='hidden' name='PAYSYSTEM_ID' value='%PAYSYSTEM_ID%'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='action' value='%ACTION%'>
    <input type='hidden' name='MERCHANT' value='%MERCHANT%'>
    <input type='hidden' name='NAME' value='%NAME%'>

    <div class='card box-primary'>
        <div class='card-header with-border'>%PAYSYS_NAME%</div>
        <div class='card-body'>
            %INPUT%
            <div class='checkbox'>
                <label>
                    <input type='checkbox' name='DELETE_MERCHANT_SETTINGS' value='1' >
                    _{DEL}_ _{SETTINGS}_!
                </label>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' form='form_PAYSYS_SETTINGS_MERCHANT' class='btn btn-primary' id='button_settings' name='change'
                   value='_{CHANGE}_'>
        </div>
    </div>

</form>

<script type='text/javascript'>
    Events.on('AJAX_SUBMIT.form_PAYSYS_SETTINGS_MERCHANT', function () {
            aModal.hide();
    });

</script>