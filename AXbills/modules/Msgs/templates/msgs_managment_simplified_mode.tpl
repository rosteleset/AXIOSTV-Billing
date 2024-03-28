<div class='card card-primary card-outline card-form form form-horizontal'>
  <div class='card-header with-border'>
    <h6 class='card-title'>_{MANAGE}_</h6>
  </div>

  <div class='card-body'>

    %PLUGINS%

    <div class='form-group'>
      <div>%TASKS_LIST%</div>
    </div>

    <div class='form-group'>
      %TICKET_ADDRESS%
    </div>

  </div>
  <div class='card-footer'>
    <input type=submit name=change value='_{CHANGE}_' class='btn btn-primary btn-sm'>
  </div>
</div>

<script>
  let buttonGroup = jQuery('#btn-group');

  if (buttonGroup) {
    jQuery("[data-button-group]").each(function () {
      buttonGroup.append(jQuery(this));
    });
  }
</script>