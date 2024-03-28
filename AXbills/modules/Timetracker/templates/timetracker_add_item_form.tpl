<div class='card card-primary card-outline card-form'>
    <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='GET' class='form form-horizontal'>
    <div class='card-header with-border'><h4 class='card-title'>%TITLE%</h4></div>
    <div class='card-body'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='ID' value='%ID%'/>
            <div class='form-group row'>
                <label class='control-label col-md-3' for='ELEMENT_ID'>_{ELEMENT}_:</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' required name='ELEMENT' id='ELEMENT_ID' value='%ELEMENT%'/>
                </div>
            </div>
            <div class='form-group row'>
                <label class="control-label col-md-3" for="DISABLE">_{FOCUS_FACTOR}_:</label>
                <div class="col-md-9 col-1 col-md-1 ">
                    <input type='checkbox' name='PRIORITY' value='1' id='checkbox_priority' value='%PRIORITY%'/>
                </div>
                <input id="ACTION_COMMENTS" name="ACTION_COMMENTS" value="" class="form-control" type="text" style="display: none;">
            </div>
    </div>
    <div class='card-footer'>
        <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='%ACTION%' value="%BTN%">
    </div>
    </form>
</div>