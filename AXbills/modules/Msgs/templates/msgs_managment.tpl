<script>
  jQuery(function () {
    //cache DOM
    var shedule_link = jQuery('#sheduleTableBtn');
    var plan_time = jQuery('#PLAN_TIME');
    var plan_date = jQuery('#PLAN_DATE');
    var plan_datetime = jQuery('#PLAN_DATETIME');

    var update_shedule_link = function (new_date) {
      if (!new_date || new_date === '0000-00-00') {
        shedule_link.prop('disabled', true);
        shedule_link.addClass('disabled');
        return;
      }

      shedule_link.prop('disabled', false);
      shedule_link.removeClass('disabled');

      shedule_link.attr('href', shedule_link.attr('data-link'));
    };

    update_shedule_link(plan_date.val());

    plan_datetime.on('dp.change', function (datetimepicker_change_event) {
      var new_moment = datetimepicker_change_event.date;
      var new_date = '';
      var new_time = '';

      if (new_moment) {
        new_date = new_moment.format('YYYY-MM-DD');
        new_time = new_moment.format('HH:MM:SS');
      }

      plan_date.val(new_date);
      plan_time.val(new_time);

      update_shedule_link(new_date);
    });

  });
</script>

<div class='card card-primary card-outline'>
  <div class='card-header'>
    <h6 class='card-title'>_{MANAGE}_</h6>
  </div>

  <div class='card-body'>
    %PLUGINS%
    <div class='form-group'>
      <div>%TASKS_LIST%</div>
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
