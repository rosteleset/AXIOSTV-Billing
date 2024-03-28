<div class='d-print-none' id='form_msg_add'>

  <form action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='MsgSendForm' id='MsgSendForm'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='sid' value='$sid'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type='hidden' id='MAX_FILES' value='%MAX_FILES%'/>

    <div class='card card-primary card-outline'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{MESSAGE}_</h4>
      </div>
      <div class='card-body form form-horizontal'>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{SUBJECT}_:</label>
          <div class='col-md-8'>
            <div class='input-container d-none'>
              <div class='d-flex bd-highlight'>
                <div class='flex-fill bd-highlight'>
                  <div class='select'>
                    <div class='input-group-append select2-append'>
                      %SUBJECT_SEL%
                    </div>
                  </div>
                </div>
                <div class='bd-highlight'>
                  <div class='input-group-append h-100'>
                    <a class='btn input-group-button rounded-left-0' data-change-input='SUBJECT_INPUT'>
                      <span class='fa fa-pen p-1'></span>
                    </a>
                  </div>
                </div>
              </div>
            </div>

            <div class='input-container input-group'>
              <input type='text' id='SUBJECT_INPUT' name='SUBJECT' class='form-control' required/>
              <div class='input-group-append'>
                <a title='_{SELECT_FROM_LIST}_' class='btn input-group-button rounded-left-0'
                   style='padding: 0.375rem 0.75rem'
                   data-change-input='SUBJECT'>
                  <span class='fa fa-list'></span>
                </a>
              </div>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{CHAPTERS}_:</label>
          <div class='col-md-8'>
            %CHAPTER_SEL%
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='MESSAGE'>_{MESSAGE}_:</label>
          <div class='col-md-8'>
            <textarea id='MESSAGE' name='MESSAGE' data-action='drop-zone' cols='70' rows='9' class='form-control'
                      required>%MESSAGE%</textarea>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{STATE}_:</label>
          <div class='col-md-8'>
            %STATE_SEL%
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{PRIORITY}_:</label>
          <div class='col-md-8'>
            %PRIORITY_SEL%
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{ATTACHMENT}_:</label>

          <div class='col-md-8' id='file_upload_holder'>
            <div class='form-group m-1'>
              <input name='FILE_UPLOAD' type='file' data-number='0'>
            </div>
          </div>
        </div>
      </div>
      <div class='card-footer'>
        <input type='submit' name='send' value='_{SEND}_' id='go' class='btn btn-primary double_click_check'>
      </div>
    </div>
  </form>
</div>
<script>
  jQuery('form#MsgSendForm').on('submit', function () {
    jQuery('#go').on('click', function (click_event) {
      cancelEvent(click_event);
      return false;
    });
    return true;
  });

  // Multi upload logic
  jQuery(function () {
    var MAX_FILES_COUNT = jQuery('#MAX_FILES').val();
    if (MAX_FILES_COUNT === '') MAX_FILES_COUNT = 3;
    initMultifileUploadZone('file_upload_holder', 'FILE_UPLOAD', MAX_FILES_COUNT);
  }());
</script>

<script src='/styles/default/js/draganddropfile.js'></script>