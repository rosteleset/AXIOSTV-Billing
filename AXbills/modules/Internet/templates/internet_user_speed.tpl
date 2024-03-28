<FORM action='$SELF_URL' METHOD=POST>
    <input type=hidden name=index value=$index>
    <input type=hidden name=CID value='%ISG_CID_CUR%'>
    <input type=hidden name=sid value='$sid'>

    <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4 class='card-title'>TURBO _{MODE}_</h4></div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-2 control-label'>_{SPEED}_:</label>
                <div class='col-md-10'>
                  %SPEED_SEL%
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type=submit name=change value='_{ACTIVATE}_' class='btn btn-primary'>
        </div>
    </div>
</FORM>
