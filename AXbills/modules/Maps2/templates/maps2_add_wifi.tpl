<div class='card card-primary card-outline box-form'>
    <div class='card-body'>
        <form name='MAPS_WIFI' id='form_MAPS_WIFI' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='qindex' value='$index'>
            <input type='hidden' name='header' value='2'>
            <input type='hidden' name='LAYER_ID' value='%LAYER_ID%'>
            <input type='hidden' name='add' value='1'>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='NAME'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input type=text id='NAME' name='NAME' value='%NAME%' class='form-control'>
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
</div>