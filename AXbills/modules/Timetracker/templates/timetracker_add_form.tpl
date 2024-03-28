<form name='form_RANGE_PICKER' id='form_RANGE_PICKER' method='GET' class='form form-horizontal'>
    <div class='card card-primary card-outline card-form'>
        <div class='card-header with-border'><h4 class='card-title'>_{FILLING_TIMETRACKER}_ %CAPTION%</h4></div>
        <div class='card-body'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='add_form' value='1'>
            %FORM_GROUP%
            %DATEPICKER%
        </div>
        <div class='card-footer'>
            <input type='submit' form='form_RANGE_PICKER' class='btn btn-primary' name='%ACTION%' value='%BTN%'>
        </div>
    </div>
</form>