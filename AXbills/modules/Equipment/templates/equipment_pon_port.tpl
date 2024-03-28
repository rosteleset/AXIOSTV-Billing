<FORM action='$SELF_URL' METHOD='POST'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='$FORM{chg_pon_port}'>
    <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
    <input type='hidden' name='TYPE' value='$FORM{TYPE}'>
    <input type='hidden' name='visual' value='$FORM{visual}'>

    <div class='card card-primary card-outline box-form center-block'>
        <div class='card-header with-border'>
            <h3 class='card-title'> _{PORT}_:  %PON_TYPE% %BRANCH%</h3>
        </div>
        <div class='card-body'>

            <div class='form-group row'>
                <label class='control-label col-md-5' for='VLAN'>VLAN:</label>

                <div class='col-md-7 control-element'>
                    %VLAN_SEL%
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-5' for='BRANCH_DESC'>_{DESCRIBE}_:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='BRANCH_DESC' value='%BRANCH_DESC%' class='form-control' ID='BRANCH_DESC'/>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
        </div>

    </div>
</FORM>

