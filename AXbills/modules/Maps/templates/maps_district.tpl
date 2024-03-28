<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{DISTRICT}_</h4></div>
    <div class='card-body'>
        <form name='MAPS_DISTRICT' id='form_MAPS_DISTRICT' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index'/>

            <!--NON STANDART DATA RETURNS TO JAVASCRIPT. will add value to response for message if json-->
            <input type='hidden' name='RETURN_FORM' value='COLOR'/>

            <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='DISTRICT_ID'>_{DISTRICT}_</label>
                <div class='col-md-9'>
                    %DISTRICT_ID_SELECT%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='COLOR'>_{COLOR}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type='color' name='COLOR' id='COLOR' value='%COLOR%'/>
                </div>
            </div>

        </form>

    </div>
    <div class='card-footer'>
        <input type='submit' form='form_MAPS_DISTRICT' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
    </div>
</div>

