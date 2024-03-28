<form name='CAMS_STREAM_ADD' id='form_CAMS_STREAM_ADD' method='post' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='SERVICE_ID' value='%SERVICE_ID%'/>
  <input type='hidden' name='TP_ID' value='%TP_ID%'/>
  <input type='hidden' name='CAMS_TP_ID' value='%CAMS_TP_ID%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
  <div class='container-fluid'>
    <div class='row'>
      <div class='col-md-6'>
        <div class='card card-primary card-outline card-big-form'>
          <div class='card-header with-border'>
            <h4 class='card-title'>_{CAMERAS}_</h4>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-minus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div id='group_form' class='form-group row'>
              <label class='control-label col-md-3 required'>_{CAMS_GROUP}_:</label>
              <div class='col-md-8'>
                %GROUPS_SELECT%
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div id='folder_form' class='form-group row'>
              <label class='control-label col-md-3'>_{FOLDER}_:</label>
              <div class='col-md-8'>
                %FOLDER_SELECT%
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3' for='OWNER_id'>_{OWNER}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' name='OWNER' value='%OWNER%' id='OWNER_id'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3 required' for='TITLE_id'>_{CAM_TITLE}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' required='required' name='TITLE' value='%TITLE%'
                       id='TITLE_id'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' required='required' name='NAME' value='%NAME%'
                       id='NAME_id'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3 required' for='HOST_id'>RTSP Host:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control'
                       required='required' name='HOST' value='%HOST%' id='HOST_id'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3 ' for='RTSP_PORT_id'>RTSP _{PORT}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' name='RTSP_PORT' value='%RTSP_PORT%' id='RTSP_PORT_id'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>
            <div class='form-group row'>
              <label class='control-label col-md-3 required' for='RTSP_PATH_id'>RTSP _{PATH}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control'
                       required='required' name='RTSP_PATH' value='%RTSP_PATH%' id='RTSP_PATH_id'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            %MODELS_FORM%

            <hr>

            <div class='form-group row'>
              <label class='control-label col-md-3 required' for='LOGIN_id'>_{LOGIN}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' required='required' name='LOGIN' value='%LOGIN%'
                       id='LOGIN_id'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3 required' for='PASSWORD_id'>_{PASSWD}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' required='required' name='PASSWORD'
                       value='%PASSWORD%' id='PASSWORD_id'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <hr>

            <div class='form-group custom-control custom-checkbox'>
              <input class='custom-control-input' type='checkbox' id='DISABLED' name='DISABLED'
                     %DISABLED_CHECKED% value='1'>
              <label for='DISABLED' class='custom-control-label'>_{DISABLED}_</label>
            </div>
          </div>
        </div>
      </div>
      <div class='col-md-6'>
        <div class='card collapsed-card card-primary card-outline card-big-form'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{OTHER}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label class='control-label col-md-3' for='EXTRA_URL'>_{EXTRA}_ URL:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' name='EXTRA_URL' value='%EXTRA_URL%'
                       id='EXTRA_URL'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3'>_{ORIENTATION}_:</label>
              <div class='col-md-8'>
                %ORIENTATION_SELECT%
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3'>_{CAMS_ARCHIVE}_:</label>
              <div class='col-md-8'>
                %ARCHIVE_SELECT%
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <div class='checkbox col-md-6 text-center'>
                <div class='form-group custom-control custom-checkbox'>
                  <input class='custom-control-input' type='checkbox' id='CONSTANTLY_WORKING' name='CONSTANTLY_WORKING'
                         %CONSTANTLY_WORKING% value='1'>
                  <label for='CONSTANTLY_WORKING' class='custom-control-label'>_{CONSTANTLY_WORKING}_
                    <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a></label>
                </div>
              </div>
              <div class='checkbox col-md-6 text-center'>
                <div class='form-group custom-control custom-checkbox'>
                  <input class='custom-control-input' type='checkbox' id='PRE_IMAGE' name='PRE_IMAGE'
                         %PRE_IMAGE% value='1'>
                  <label for='PRE_IMAGE' class='custom-control-label'>_{PRE_IMAGE}_
                    <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a></label>
                </div>
              </div>
              <div class='checkbox col-md-6 text-center'>
                <div class='form-group custom-control custom-checkbox'>
                  <input class='custom-control-input' type='checkbox' id='LIMIT_ARCHIVE' name='LIMIT_ARCHIVE'
                         %LIMIT_ARCHIVE% value='1'>
                  <label for='LIMIT_ARCHIVE' class='custom-control-label'>_{LIMIT_ARCHIVE}_
                    <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a></label>
                </div>
              </div>
              <div class='checkbox col-md-6 text-center'>
                <div class='form-group custom-control custom-checkbox'>
                  <input class='custom-control-input' type='checkbox' id='ONLY_VIDEO' name='ONLY_VIDEO'
                         %ONLY_VIDEO% value='1'>
                  <label for='ONLY_VIDEO' class='custom-control-label'>_{ONLY_VIDEO}_
                    <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a></label>
                </div>
              </div>
            </div>
            <div class='form-group row'>
              <label class='control-label col-md-3'>_{PRE_IMAGE}_ URL:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' name='PRE_IMAGE_URL' value='%PRE_IMAGE_URL%'
                       id='PRE_IMAGE_URL'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3'>_{TYPE_FOR_SERVICE}_:</label>
              <div class='col-md-8'>
                %TYPE_SELECT%
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3'>_{CAMS_VISIBILITY}_:</label>
              <div class='col-md-8'>
                <input type='text' class='form-control' name='LENGTH' value='%LENGTH%'
                       id='LENGTH'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3'>_{CAMERA_ANGLE}_:</label>
              <div class='col-md-8'>
                <input type='number' class='form-control' name='ANGEL' value='%ANGEL%' max='360'
                       id='ANGEL'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3'>_{CAMERA_ANGLE_LOCATION}_:</label>
              <div class='col-md-8'>
                <input type='number' class='form-control' name='LOCATION_ANGEL' value='%LOCATION_ANGEL%' max='360'
                       id='LOCATION_ANGEL'/>
              </div>
              <a href='#' data-toggle='tooltip' title=''><span class='fa fa-question-circle'></span></a>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CAMS_STREAM_ADD' class='btn btn-primary' name='submit'
             value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>

<script>
  if ('%FOLDERS%') {
    var folder_select = document.getElementById('FOLDER_ID');
    folder_select.textContent = '';
    folder_select.value = '';

    autoReload();
  } else {
    jQuery('#folder_form').hide();
  }

  jQuery(document).ready(function () {
    jQuery('[data-toggle="tooltip"]').tooltip();
  });

  function autoReload() {
    var folder = 0;
    if ('%FOLDERS%' && '%FOLDERS%' > 0)
      folder = '%FOLDERS%';

    var groups = document.getElementById('GROUP_ID');
    var result = groups.value;
    jQuery.post('$SELF_URL', 'header=2&get_index=cams_get_group_folders&GROUP_ID=' + result + '&FOLDER_ID=' + folder, function (data) {
      folder_select.textContent = '';
      folder_select.value = '';
      folder_select.innerHTML = data;
    });
  }
</script>