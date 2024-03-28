<FORM action=$SELF_URL METHOD=POST class='form-horizontal'>
    <input type=hidden name=index value='$index'>
    <input type=hidden name=ID value='$FORM{chg}'>

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'>_{TRUNKS}_</div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>VOIP _{PROVIDER}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=PROVIDER_NAME value='%PROVIDER_NAME%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=NAME value='%NAME%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>_{DEL}_ _{PREFIX}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=REMOVEPREFIX value='%REMOVEPREFIX%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>_{ADD}_ _{PREFIX}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=ADDPREFIX value='%ADDPREFIX%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>_{PROTOCOL}_</label>
                <div class='col-md-9'>
                    %PROTOCOL_SEL%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>_{PROVIDER}_ IP</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=PROVIDER_IP value='%PROVIDER_IP%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>_{LOGIN}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=USERNAME value='%USERNAME%'>
                </div>
            </div>
             <div class='form-group row'>
                <label class='col-md-3 control-label'>_{PASSWD}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=password name=PASSWORD value='%PASSWORD%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>_{EXTRA}_ _{PARAMS}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=EXT_PARAMS value='%EXT_PARAMS%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>_{FAILOVER_TRUNK}_</label>
                <div class='col-md-9'>
                    %FAILOVER_TRUNK_SEL%
                </div>
            </div>
            <div class='form-group row'>
                <label for='DISABLE' class='control-label col-md-3'>_{DISABLE}_:</label>
                <div class='col-md-3'>
                    <input type='checkbox' value='1' name='DISABLE'  id='DISABLE' %DISABLE%/>
                </div>
            </div>
        </div>

        <div class='card-footer'>
            <input class='btn btn-primary' type=submit name=%ACTION% value='%LNG_ACTION%'>
        </div>
    </div>
</FORM>