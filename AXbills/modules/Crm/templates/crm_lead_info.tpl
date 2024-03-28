<div class='row'>
  %LEAD_PROFILE_PANEL%
  <div class='col-md-9'>
    %PROGRESSBAR%
  </div>
</div>

<div class='modal fade' id='leadTags' tabindex='-1' role='dialog' aria-labelledby='myModalLabel' aria-hidden='true'>
  <div class='modal-dialog'>
    <div class='modal-content'>
      <div class='modal-header'>
        <h4 class='modal-title' id='myModalLabel'>_{ADD_TAGS}_</h4>
        <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
      </div>
      <form id='lead_tags' method='post' action=''>
        <input type='hidden' name='index' value=%index%>
        <input type='hidden' name='LEAD_ID' value='%LEAD%'>
        <div class='modal-body'>
          %MODAL_TAGS%
        </div>
        <div class='modal-footer'>
          <button type='button' data-dismiss='modal' class='btn btn-danger'>_{CLOSE}_</button>
          <button type='submit' form='lead_tags' class='btn btn-primary' name='SAVE_TAGS' value='1'>_{SAVE}_</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
  Events.on('AJAX_SUBMIT.form_CRM_LEAD_SEARCH', function () {
    location.reload(false)
  })
</script>