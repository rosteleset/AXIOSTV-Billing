<div class='card card-primary card-outline box-form center-block'>
    <div class='card-header text-center'><h4>_{CAMERAS}_</h4></div>
    <div class='card-body'>

        <form name='CAMS_STREAM_ADD' id='form_CAMS_STREAM_ADD' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='ID' value='%ID%'/>
            <input type='hidden' name='UID' value='%UID%'/>
            <input type='hidden' name='sid' value='$sid'/>
            <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' required='required' name='NAME' value='%NAME%' id='NAME_id'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='HOST_id'>RTSP Host</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control'
                           required='required' name='HOST' value='%HOST%' id='HOST_id'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='RTSP_PORT_id'>RTSP _{PORT}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control'
                           required='required' name='RTSP_PORT' value='%RTSP_PORT%' id='RTSP_PORT_id'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3 required' for='RTSP_PATH_id'>RTSP _{PATH}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control'
                           required='required' name='RTSP_PATH' value='%RTSP_PATH%' id='RTSP_PATH_id'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{ORIENTATION}_</label>
                <div class='col-md-9'>
                    %ORIENTATION_SELECT%
                </div>
            </div>

            <hr>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='LOGIN_id'>_{LOGIN}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' required='required' name='LOGIN' value='%LOGIN%' id='LOGIN_id'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='PASSWORD_id'>_{PASSWD}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' required='required' name='PASSWORD' value='%PASSWORD%' id='PASSWORD_id'/>
                </div>
            </div>

            <hr>

            <div class='checkbox text-center'>
                <label>
                    <input type='checkbox' %DISABLED_CHECKED% data-return='1' value='1' name='DISABLED'/>
                    <strong>_{DISABLED}_</strong>
                </label>
            </div>

        </form>

    </div>

    <div class='card-footer'>
        <input type='submit' form='form_CAMS_STREAM_ADD' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
    </div>

</div>