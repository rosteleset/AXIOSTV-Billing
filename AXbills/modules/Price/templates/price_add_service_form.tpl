<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='%ID%'>
    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'><h4>_{ADD_SERVICE}_</h4></div>
        <div class='card-body'>
            <div class='form-group'>
                <label class='control-label col-md-3 required'>_{GROUP}_</label>
                <div class='col-md-9'>
                    %PRICE_GROUP%
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for="NAME">_{NAME}_</label>
                <div class='col-md-9'>
                    <input required='' type='text' class='form-control' id="NAME" name='NAME' value='%NAME%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for="TYPE">_{INPUT_TYPE}_</label>
                <div class='col-md-9'>
                    %INPUT_TYPE%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for="PRICE">_{PRICE}_,<span class='fa fa-usd'></span></label>
                <div class='col-md-9'>
                    <input required='' type='text' class='form-control' id="PRICE" name='PRICE' value='%PRICE%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for="COMMENTS">_{DESCRIBE}_</label>
                <div class='col-md-9'>
                    <textarea class='form-control' rows='5' id="COMMENTS" name='COMMENTS'>%COMMENTS%</textarea>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
        </div>
    </div>
</form>
