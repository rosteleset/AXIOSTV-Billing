<div class='col-xs-12 col-md-6'>
    <div class='card card-primary card-outline'>
        <div class='card-header with-border'>_{SESSIONS}_</div>
        <div class='card-body'>
            <div class='form-group'>
                <label class='col-md-3 control-label'>SUM(>,<)</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=SUM value='%SUM%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label'>IP (>,<)</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=IP value='%IP%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label'>CID</label>
                <div class='col-md-9'>
                    <input class='form-control mac-input' type=text name=CID value='%CID%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label'>NAS</label>
                <div class='col-md-9'>%SEL_NAS%</div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label'>NAS Port</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=NAS_PORT value='%NAS_PORT%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label'>SESSION_ID</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=ACCT_SESSION_ID value='%ACCT_SESSION_ID%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label'>_{STATUS}_:</label>
                <div class='col-md-9'>%TERMINATE_CAUSE_SEL%</div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{LAST_ENTRIES}_</label>
                <div class='col-md-9'>
                    <input class='form-control tcal' type=text name='LAST_SESSION' value='%LAST_SESSION%'>
                </div>
            </div>
        </div>
    </div>
</div>
