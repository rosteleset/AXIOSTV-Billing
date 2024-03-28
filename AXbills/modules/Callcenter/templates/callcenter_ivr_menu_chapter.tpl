<form action=$SELF_URL method=post>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value='%ID%'>

    <div class='card card-primary card-outline card-form'>
        <div class='card-header'>
            <div class='card-title'>
                <h4>IVR _{MENU}_ _{CHAPTERS}_</h4>
            </div>
        </div>
        <div class='card-body'>

            <div class='form-group row'>
                <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
                <div class='col-md-9'>
                    <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3' for='NUMBERS'>_{NUMBERS}_:</label>
                <div class='col-md-9'>
                    <input id='NUMBERS' name='NUMBERS' value='%NUMBERS%' placeholder='%NUMBERS%' class='form-control'
                           type='text'>
                </div>
            </div>
<!--
            <div class='form-group row'>
                <label class='control-label col-md-3' for='DISABLE'>_{DISABLE}_:</label>
                <div class='col-md-9'>
                    <input id='DISABLE' name='DISABLE' value='1' %DISABLE% type='checkbox'>
                </div>
            </div>
-->
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        </div>
    </div>
</form>