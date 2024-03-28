<form action='$SELF_URL' METHOD='POST' name='user' ID='user' class='form-horizontal'>
    <input type=hidden name=sid value='$sid'>
    <input type=hidden name=UID value='%UID%'>
    <input type=hidden name=ID value='%ID%'>
    <input type=hidden name=m value='%m%'>
    <input type=hidden name='index' value='$index'>

    <fieldset>

        <div class='card card-primary card-outline card-form'>
            <div class='card-header with-border'>
                <h4 class='card-title'>_{TARIF_PLANS}_: %ID%</h4>
            </div>

            <div class='card-body'>

                <div class='row no-padding'>
                    <div class="col-md-12 text-center">
                        %MENU%
                    </div>
                </div>

                <div class='form-group row'>
                    <label class='control-label col-md-3' for='TARIF'>_{FROM}_:</label>
                    <div class='col-md-9 text-left'>
                        <input type=text name=TARIF value='%TP_ID% %TP_NAME% %DESCRIBE_AID%' ID='TARIF' class='form-control' readonly
                               style='text-align: inherit;'>
                    </div>
                </div>

                <div class='form-group row'>
                    <label class='control-label col-md-3' for='TARIF_PLAN'>_{TO}_:</label>
                    <div class='col-md-9 text-left'>
                        %TARIF_PLAN_SEL%
                    </div>
                </div>

                <div class='form-group row'>
                    <label class='control-label col-md-5' for='GET_ABON'>_{GET}_ _{ABON}_:</label>
                    <div class='col-md-2 mt-2'>
                        <input type=checkbox name=GET_ABON ID='GET_ABON' value=1 checked>
                    </div>

                    <label class='control-label col-md-3' for='RECALCULATE'>_{RECALCULATE}_:</label>
                    <div class='col-md-2 mt-2'>
                        <input type=checkbox name=RECALCULATE value=1 checked>
                    </div>
                </div>

                <div class='form-group row'>
                    %PARAMS%
                </div>

            </div>
        </div>

        <div class='card-footer'>
            <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
        </div>


    </fieldset>

    <div class='form-group row'>
        <div class='col-md-12'>
            %SHEDULE_LIST%
        </div>
    </div>
</form>

<script>
    jQuery('.datepicker').on('change', function () {
        jQuery('input:radio[name="period"]').filter('[value="2"]').prop('checked', true);
    });
</script>