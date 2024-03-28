<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{CABLE_RESERVE}_</h4></div>
    <div class='card-body'>
        <form name='CABLECAT_CROSS' id='form_CABLECAT_CROSS' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index' />
            <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1' />
            <input type='hidden' name='ID' value='%ID%' />

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='NAME_ID'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' value='%NAME%'  required name='NAME'  id='NAME_ID'  />
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='LENGTH'>_{LENGTH}_</label>
                <div class='col-md-9'>
                    <input type='number' step='0.01' class='form-control' name='LENGTH' value='%LENGTH%' id="LENGTH">
                </div>
            </div>

        </form>

    </div>
    <div class='card-footer'>
        <input type='submit' form='form_CABLECAT_CROSS' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
    </div>
</div>