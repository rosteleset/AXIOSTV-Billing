<form action='$SELF_URL' method='post' enctype='multipart/form-data'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='add_delivery' value='%ID%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='UPLOAD_FILES' value=0>

  <div class='card container-md'>
    <div class='card-header'>
      <h4 class='card-title'>
        _{ADD_DELIVERY}_
      </h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label required' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-9'>
          <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' required placeholder='%SUBJECT%'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label required' for='TEXT'>_{MESSAGES}_:</label>
        <div class='col-md-9'>
          <textarea class='form-control' required rows='5' id='TEXT' name='TEXT'
                    placeholder='_{TEXT}_'>%TEXT%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{ATTACHMENT}_:</label>
        <div class='col-md-9'>
          <div id='file_upload_holder' class='form-file-input'>
            <div class='form-group m-1'>
              <input id='FILE_UPLOAD' name='FILE_UPLOAD' type='file' data-number='0' class='fixed' data-action='drop-zone'>
            </div>
          </div>
          <div id='ATTACHMENTS_CONTAINER' class='input-group d-none'>
            <div id='ATTACHMENTS' class='form-file-input'></div>
            <div class='input-group-append'>
              <div class='input-group-text clear_results cursor-pointer' id='CHANGE_FILES_BTN'>
                <span class='fa fa-pencil-alt'></span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='DELIVERY_SEND_DATE'>_{SEND_TIME}_:</label>
        <div class='col-md-9'>
          %DATE_PIKER%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='DELIVERY_SEND_TIME'></label>
        <div class='col-md-9'>
          %TIME_PIKER%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='STATUS'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATUS_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-9'>
          %PRIORITY_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='SEND_METHOD'>_{SEND}_:</label>
        <div class='col-md-9'>
          %SEND_METHOD_SELECT%
        </div>
      </div>
    </div>
    <div class='card-footer'><input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'></div>
  </div>
</form>

<script>
  let attachments = [];

  try {
    attachments = JSON.parse('%ATTACHMENTS%');
  }
  catch (e) {
    console.log(e);
  }

  let attachmentContainer = document.getElementById('ATTACHMENTS_CONTAINER');
  let attachmentsBlock = document.getElementById('ATTACHMENTS');
  let fileUploadContainer = document.getElementById('file_upload_holder')

  if (attachments.length > 0) {
    fileUploadContainer.classList.add('d-none');
    attachmentContainer.classList.remove('d-none');
  }
  else {
    jQuery(`[name='UPLOAD_FILES']`).val(1);
  }

  attachments.forEach(attachment => {
    let formGroup = document.createElement('div');
    formGroup.classList.add('form-group');
    formGroup.classList.add('m-1');

    let btn = document.createElement('a');
    btn.href = attachment.url;
    btn.target = '_blank';
    btn.innerText = attachment.filename;

    let size = document.createElement('span');
    size.innerText = ` (_{SIZE}_: ${attachment.size})`;

    formGroup.appendChild(btn);
    formGroup.appendChild(size);
    attachmentsBlock.appendChild(formGroup);
  });

  jQuery('#CHANGE_FILES_BTN').on('click', function() {
    fileUploadContainer.classList.remove('d-none');
    attachmentContainer.classList.add('d-none');
    jQuery(`[name='UPLOAD_FILES']`).val(1);
  });

  var MAX_FILES_COUNT = jQuery('#MAX_FILES').val();
  if (!MAX_FILES_COUNT || MAX_FILES_COUNT === '') MAX_FILES_COUNT = 3;

  initMultifileUploadZone('file_upload_holder', 'FILE_UPLOAD', MAX_FILES_COUNT);
</script>
<script src='/styles/default/js/draganddropfile.js'></script>