<form class='form-horizontal' action='$SELF_URL' method='post' role='form' id='crm_map_multiple_update'>
  <input type=hidden name='qindex' value='$index'>
  <input type='hidden' name='ID' id='ID' value='%IDS%'>
  <input type='hidden' name='header' value='2'>
  <input type='hidden' name='CRM_MULTISELECT' value='1'>

  <div class='card card-primary card-outline %PARAMS%'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{MULTIUSER_OP}_</h4>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{RESPOSIBLE}_:</label>
        <div class='col-md-8'>
          %RESPONSIBLE_ADMIN%
        </div>
      </div>
      <div class='form-group row' style='%DISPLAY_TAGS%'>
        <label class='col-md-4 col-form-label text-md-right' for='TAGS'>_{TAGS}_:</label>
        <div class='col-md-8'>
          %TAGS_SEL%
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' name='CRM_MULTISELECT' value='_{ACCEPT}_' class='btn btn-primary'>
    </div>
  </div>
</form>
%LEADS_TABLE%

<script>
  jQuery(function () {
    let form = jQuery('form#crm_map_multiple_update');
    let submit_btn = form.find('button[type="submit"]');

    form.on('submit', function (e) {
      e.preventDefault();
      let formData = form.serialize();

      submit_btn.prop('disabled', true);

      jQuery.post('/admin/index.cgi', formData, function (data) {
        submit_btn.prop('disabled', false);
        aModal.hide();
      });
    });
  });
</script>
