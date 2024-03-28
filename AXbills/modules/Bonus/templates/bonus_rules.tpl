<form name='user' class='form-horizontal'>
    <input type=hidden name='ID' value='%ID%'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='chg' value='%chg%'>
    <input type=hidden name='RULES' value='1'>
    <input type=hidden name='TP_ID' value='%TP_ID%'>
    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'><h4>_{RULES}_</h4></div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label col-md-4' for='PERIOD'>_{PERIOD}_</label>
                <div class='col-md-8'>
                    %PERIOD%
                </div>
            </div>
            <div class='form-group row'>
                <label class='control-label col-md-4' for='RULE'>_{RULES}_</label>
                <div class='col-md-8'>
                    %RULE%
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-4' for='RULE_VALUE'>_{VALUE}_</label>
                <div class='col-md-8'>
                    <input required='' type='text' class='form-control' id="RULE_VALUE" name='RULE_VALUE' value='%RULE_VALUE%'/>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-4' for='ACTIONS'>_{BONUS}_</label>
                <div class='col-md-8'>
                    <input required='' type='text' class='form-control' id="ACTIONS" name='ACTIONS' value='%ACTIONS%'/>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name=%ACTION% value='%LNG_ACTION%'>
        </div>
    </div>
</form>