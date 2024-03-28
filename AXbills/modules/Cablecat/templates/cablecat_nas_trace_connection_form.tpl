<div class='row'>
  <div class='col-md-4'>
    <div class='form-group'>
      <label class='control-label col-md-12' for='NAS_ID'>_{EQUIPMENT}_</label>
      <div class='col-md-12'>
        %NAS_ID_SELECT%
      </div>
    </div>
  </div>
  <div class='col-md-4'>
    <div class='form-group'>
      <label class='control-label col-md-12' for='ENDPOINT_NAS_ID'>_{TRACE_UP_TO}_</label>
      <div class='col-md-12'>
        %END_NAS_ID_SELECT%
      </div>
    </div>
  </div>
  <div class='col-md-4'>
    <div class='col-md-12'></div>
    <div class='col-md-12'>
      <input type='submit' class='btn btn-primary btn-lg' name='action' value='_{SHOW}_'/>
    </div>
  </div>
</div>

<div class='text-left'>
  %PATH_VIEW%
</div>

<script>
  jQuery(function () {
    var index            = '$index';
    var equipment_select = jQuery('select#NAS_ID');
    var endpoint_select  = jQuery('select#ENDPOINT_NAS_ID');

    function updateSelectValues(select, new_options_html) {
      var old_value = select.val();
      select.empty().html(new_options_html);
      updateChosen(function () {
        select.trigger('change');
        if (old_value) {
          renewChosenValue(select, old_value);
        }
      });
    }

    function requestEquipment() {
      jQuery.get('?qindex=' + index + '&header=2&&get_nases=1&as_option=1', function (data) {
        updateSelectValues(equipment_select, data);
      });
    }

    function requestEndPoints() {
      var nas_id = equipment_select.val();
      jQuery.get('?qindex=' + index + '&header=2&NAS_ID=' + nas_id + '&get_endpoints=1&as_option=1', function (data) {
        updateSelectValues(endpoint_select, data);
      });
    }

    if (!equipment_select.val()) {
      requestEquipment();
    }
    else if (equipment_select.val()) {
      requestEndPoints();
    }

    equipment_select.on('change', requestEndPoints);
  });
</script>