<FORM action='$SELF_URL' METHOD='POST' class='form-horizontal'>
    <input type='hidden' name='SESSION_ID' value='%SESSION_ID%'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='UID' value='%UID%'>
    <input type='hidden' name='sid' value='$sid'>
    <input type='hidden' name='ACCT_INTERIUM_INTERVAL' value='%ACCT_INTERIUM_INTERVAL%'>

    <div class='card card-primary card-outline box-form center-block'>
        <div class='card-header with-border'>
            <h4>_{LOGON}_ Internet</h4>
        </div>
        <div class='card-body'>

            %MENU%


            <div class='form-group'>
                <label class='control-label col-md-6' for='IP'>IP:</label>

                <div class='col-md-6 control-element'>
                    %IP% %IP_INPUT_FORM%
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-6' for='NAS'>_{NAS}_:</label>

                <div class='col-md-6 control-element'>
                    %NAS_ID% %NAS_SEL%
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' name='%ACTION%' value='%ACTION_LNG% Internet' class='btn btn-primary'>
        </div>

        </fieldset>


    </div>
</form>

%ONLINE%

