<form action='$SELF_URL' method='post' name=pay_to class='form-horizontal'>

    <input type=hidden name='index' value='$index'>

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'>
            <h4>QUOTA</h4>
        </div>
        <div class='card-body'>
            <div class='form-group'>
                <label class='control-label col-md-3' for='LOGIN'>_{LOGIN}_:</label>
                <div class='col-md-9'>
                    <div class='input-group'>
                        <input type=text name='LOGIN' value='%LOGIN%' ID='LOGIN' class='form-control' readonly>
                    </div>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='SPEED'>_{SPEED}_</label>
                <div class='col-md-9'>
                    <input id='SPEED' name='SPEED' value='%SPEED%' data-date-orientation='bottom' placeholder='%SPEED%'
                           class='form-control' type='text' readonly>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='IP'>IP</label>
                <div class='col-md-9'>
                    <input id='IP' name='IP' value='%IP%' data-date-orientation='bottom' placeholder='%IP%'
                           class='form-control' type='text' readonly>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='QUOTA'>QUOTA</label>
                <div class='col-md-9'>
                    <input id='QUOTA' name='QUOTA' value='%QUOTA%' data-date-orientation='bottom' placeholder='%QUOTA%'
                           class='form-control' type='text' readonly>
                </div>
            </div>


<!--
            <input type=submit name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
-->
        </div>
    </div>

</form>
