<form class='form-horizontal' action='$SELF_URL' METHOD='POST' role='form'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='chg'   value='$FORM{chg}'>

    <fieldset>
        <div class='card card-primary card-outline box-form'>
            <div class='card-header with-border'><h4 class='card-title'>_{RULES}_</h4></div>
            <div class='card-body'>

                <div class='form-group'>
                    <label for='BLOCKTYPE' class='control-label col-sm-4'>_{BLOCKTYPE}_</label>
                    <div class='col-sm-8'>
                        %BLOCKTYPE_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label for='HASH' class='control-label col-sm-4'>_{VALUE}_</label>
                    <div class='col-sm-8'>
                        <input class='form-control' id='HASH' placeholder='_{VALUE}_' name='HASH' value='%HASH%'>
                    </div>
                </div>

            <div class='card-footer'>
                <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
            </div>
        </div>
    </fieldset>
</form>
