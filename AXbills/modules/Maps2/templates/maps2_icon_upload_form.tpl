<div class='card-header border-0 p-1'>
  <h4 class='card-title'>_{ICON}_</h4>
</div>

<div class='card-body' id='ajax_upload_modal_body'>
  <form class='form form-inline' name='ajax_upload_form' id='ajax_upload_form' data-timeout='%TIMEOUT%' method='post'>
    <input type='hidden' name='get_index' value='%CALLBACK_FUNC%'/>
    <input type='hidden' name='IN_MODAL' value='1'/>
    <input type='hidden' name='header' value='2'/>

    <div class='form-group row'>
      <label class='control-label col-md-3 required' for='UPLOAD_FILE'>_{FILE}_</label>
      <div class='col-md-9'>
        <input type='file' name='UPLOAD_FILE' id='UPLOAD_FILE' class='control-element' required/>
      </div>
    </div>
  </form>
</div>
<div class='card-footer text-right'>
  <button type='submit' class='btn btn-primary' id='ajax_upload_submit' form='ajax_upload_form'>
    _{ADD}_
  </button>
</div>

<script src='/styles/default/js/ajax_upload.js'></script>

<script>
  var filename = undefined;
  jQuery('#UPLOAD_FILE').on('change', function () {
    filename = jQuery(this).val().split('\\').pop().split('\.').shift();
  });

  jQuery('#ajax_upload_submit').on('click', function () {
    setTimeout(function () {
      jQuery('.modal').modal('hide');
      if (updateIcons)
        updateIcons(filename);

    }, 2000);
  });

</script>
