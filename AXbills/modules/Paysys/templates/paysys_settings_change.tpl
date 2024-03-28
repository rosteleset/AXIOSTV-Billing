<form name='PAYSYS_SETTINGS' id='form_PAYSYS_SETTINGS' method='post' class='form form-horizontal %AJAX_SUBMIT_FORM%'>

    <input type='hidden' name='PAYSYSTEM' value='%PAYSYSTEM_NAME%'>
    <input type='hidden' name='PAYSYSTEM_ID' value='%PAYSYSTEM_ID%'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='action' value='%ACTION%'>

    <div class='card box-primary'>
        <div class='card-header with-border'>%PAYSYS_NAME%</div>
        <div class='card-body'>
            <div class='form-group'>
                <label class='control-label col-md-6' style='text-align: right'>_{VERSION}_</label>
                <label class='control-label col-md-6' style='text-align: left'>%VERSION%</label>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4' style='text-align: right'>IP</label>
                <div class='col-md-8'>
                    <input type='text' class='form-control col-md-6'>
                </div>
            </div>
            %INPUT%
            <div class='checkbox'>
                <label>
                    <input type='checkbox' name='PAYSYS_CONNECT' value='1' %PAYSYS_CONNECT_CHECKED% data-return='1'>
                    Включить систему!
                </label>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' form='form_PAYSYS_SETTINGS' class='btn btn-primary' id='button_settings' name='change'
                   value='_{CHANGE}_'>
            <input type='submit' class='btn btn-danger pull-right' name='clear' value='_{DEL}_ _{SETTINGS}_'>
        </div>
    </div>

</form>

<script type='text/javascript'>
    jQuery(function () {

    });
    Events.on('AJAX_SUBMIT.form_PAYSYS_SETTINGS', function () {
        jQuery('#button_settings').click(function () {
            aModal.hide();
        });
        location.reload(false);
    });

</script>