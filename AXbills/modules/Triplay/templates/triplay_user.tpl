<form action=$SELF_URL METHOD=POST>

    <input type='hidden' name='index' value=%INDEX%>
    <input type='hidden' name='UID' value=%UID%>

    <div class='card card-primary card-outline card-big-form'>
        <div class='card-header with-border'>
            <h4 class='card-title'>3Play</h4></div>

        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-4 control-label'>_{TARIF_PLAN}_</label>
                <div class='col-md-8'>
                    %TP_SEL%
                </div>
            </div>

            <div class='form-group row' style='background-color: %STATUS_COLOR%'>
                <label class='col-md-4 control-label'>_{STATUS}_</label>
                <div class='col-md-8'>
                    %STATUS_SEL%
                </div>
            </div>

            %SERVICES_INFO%
            <br>
            <div class='form-group'>
                <label for='COMMENTS' class='col-md-12'>
                    <span class='col'>_{COMMENTS}_:</span>
                </label>

                <div class='col-md-12'>
                    <textarea rows='5' cols='100' name='COMMENTS' class='form-control' id='COMMENTS'>%COMMENTS%</textarea>
                </div>

            </div>

        </div>

        <div class='card-footer'>
            %BACK_BUTTON%
            <input type='submit' class='btn btn-primary' name='%ACTION%' id='%ACTION%' value='%ACTION_LNG%'>
            %DEL_BUTTON%
        </div>

    </div>

</form>