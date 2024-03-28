<div class='card card-primary card-outline %PARAMS% collapsed-card'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{MULTIUSER_OP}_</h4>
    <div class='card-tools float-right'>
      <button type='button' id='mu_status_box_btn' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-plus'></i>
      </button>
    </div>
  </div>

  <div class='card-body'>

    <div class='row'>
      <div class='col-md-6'>
        <div class='form-group row'>
          <label class='col-form-label text-md-right col-md-4'>_{RESPOSIBLE}_:</label>
          <div class='col-md-8'>
            %RESPONSIBLE_ADMIN%
          </div>
        </div>
      </div>
      <div class='col-md-6'>
        <div class='form-group row' style='%DISPLAY_TAGS%'>
          <label class='col-md-4 col-form-label text-md-right' for='TAGS'>_{TAGS}_:</label>
          <div class='col-md-8'>
            %TAGS_SEL%
          </div>
        </div>
      </div>
    </div>

    <div class='row float-right'>
      <input name='CRM_MULTIMERGE' form='crm_lead_multiselect' value='_{MERGE}_' class='btn btn-success mr-1' type='submit'>
      <input name='CRM_MULTISELECT' form='crm_lead_multiselect' value='_{ACCEPT}_' class='btn btn-primary' type='submit'>
    </div>
  </div>
</div>

<script>
  jQuery('[name="CRM_MULTIMERGE"]').on('click', function () {
    jQuery('[name="CRM_MULTISELECT"]').attr('disabled', 'disabled');
  });
</script>