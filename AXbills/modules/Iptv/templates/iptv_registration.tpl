<script language='JavaScript'>
    function autoReload() {
        document.iptv_user_info.add_form.value = '1';
        document.iptv_user_info.TP_ID.value = '';
        document.iptv_user_info.new.value = '%new%';
        document.iptv_user_info.step.value = '%step%';
        document.iptv_user_info.submit();
    }
</script>

<link href='/styles/default/css/client.css' rel='stylesheet'>

<form action='$SELF_URL' method='post' name='iptv_user_info' class='form-horizontal'>
    <input type='hidden' name='TP_IDS' value='%TP_IDS%'>
    <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
    <input type='hidden' name='module' value='Iptv'>

    <div class='card center-block container-md'>

        <div class='card-header with-border'>
            <h4 class='card-title'>_{REGISTRATION}_</h4>
        </div>
        <div class='card-body'>
            %CHECKED_ADDRESS_MESSAGE%

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='LOGIN'>_{LOGIN}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='LOGIN' name='LOGIN' value='%LOGIN%' required placeholder='_{LOGIN}_' class='form-control'
                            type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='FIO'>_{FIO}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='FIO' name='FIO' value='%FIO%' required placeholder='_{FIO}_' class='form-control'
                            type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='PHONE'>_{PHONE}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='FIO' name='PHONE' value='%PHONE%' required placeholder='_{PHONE}_' id='PHONE'
                            class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='EMAIL'>E-MAIL:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='E-mail' class='form-control'
                            type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='SUBSCRIBE'>_{SERVICES}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        %SUBSCRIBE_FORM%
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4' for='TP_ID'>_{TARIF_PLAN}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        %TP_ADD%
                    </div>
                </div>
            </div>

            %ADDRESS_TPL%

            %PAYMENTS%

            <div class='form-group text-center'>
                <label class='control-element col-md-12 ' for='RULES'>_{RULES}_</label>
                <div class='col-md-12'>
                    <textarea ID='RULES' cols=60 rows=8 class='form-control' readonly> %_RULES_% </textarea>
                </div>
            </div>

            <div class='form-group'>
                <div class='custom-control custom-checkbox'>
                    <input class='custom-control-input' type='checkbox' id='ACCEPT_RULES' required name='ACCEPT_RULES' value='1'>
                    <label for='ACCEPT_RULES' class='custom-control-label'>_{ACCEPT}_</label>
                </div>
            </div>

            %CAPTCHA%
        </div>

        <div class='card-footer'>
            %FB_INFO%
            <input type=submit name=reg value='_{REGISTRATION}_' class='btn btn-primary'>
        </div>

    </div>
</FORM>


%MAPS%

