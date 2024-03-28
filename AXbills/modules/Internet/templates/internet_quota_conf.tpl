<form action='$SELF_URL' method='post' name=pay_to class='form-horizontal'>

    <input type=hidden name='index' value='$index'>

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'>
            <h4>QUOTA</h4>
        </div>
        <div class='card-body'>
            <div class='form-group'>
                <label class='control-label col-md-3' for='QUOTA'>QUOTA:</label>
                <div class='col-md-9'>
                    <div class='input-group'>
                        <input type=text name='QUOTA' value='%QUOTA%' ID='QUOTA' class='form-control'>
                    </div>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='DAYS'>_{DAYS}_</label>
                <div class='col-md-9'>
                    <input id='DAYS' name='DAYS' value='%DAYS%' data-date-orientation='bottom' placeholder='%DAYS%'
                           class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='SPEED_IN'>_{SPEED}_ IN</label>
                <div class='col-md-9'>
                    <input id='SPEED_IN' name='SPEED_IN' value='%SPEED_IN%' data-date-orientation='bottom' placeholder='%SPEED_IN%'
                           class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='SPEED_OUT'>_{SPEED}_ OUT</label>
                <div class='col-md-9'>
                    <input id='SPEED_OUT' name='SPEED_OUT' value='%SPEED_OUT%' data-date-orientation='bottom' placeholder='%SPEED_OUT%'
                           class='form-control' type='text'>
                </div>
            </div>


            <input type=submit name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>

        </div>
    </div>

</form>
