<div class='card card-primary card-outline'>
  <div class='card-header with-border'><h4 class='card-title'>_{CROSS}_ : %WELL%</h4></div>
  <div class='card-body'>
    <form name='CABLECAT_COMMUTATION_ADD_CROSS_MODAL' id='CABLECAT_COMMUTATION_ADD_CROSS_MODAL' method='post'
          class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='operation' value='ADD'/>
      <input type='hidden' name='entity' value='CROSS'/>
      <input type='hidden' name='COMMUTATION_ID' value='%COMMUTATION_ID%'/>

      <div class='form-group row'>
        <label class='control-label col-md-3'>_{CROSS}_:</label>
        <div class='col-md-9'>
          %CROSS_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3'>_{PORTS}_:</label>
        <div class='col-md-4'>%PORT_START_SELECT%</div>
        <div class='col-md-1'></div>
        <div class='col-md-4'>%PORT_FINISH_SELECT%</div>
      </div>

    </form>

  </div>

  <div class='card-footer'>
    <input type='submit' form='CABLECAT_COMMUTATION_ADD_CROSS_MODAL' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>

</div>
<script>
  jQuery(function () {

    /* FORM LOGIC */
    jQuery('#CABLECAT_COMMUTATION_ADD_CROSS_MODAL').on('submit', ajaxFormSubmit);
    Events.off('AJAX_SUBMIT.CABLECAT_COMMUTATION_ADD_CROSS_MODAL');
    Events.once('AJAX_SUBMIT.CABLECAT_COMMUTATION_ADD_CROSS_MODAL', function (response) {
      if (response.MESSAGE_CROSS_ADDED) {
        aTooltip.displayMessage(response.MESSAGE_CROSS_ADDED, 2000);
        location.reload();
      }
    });

    /* PORT SELECT LOGIC */
    var cross_select = jQuery('select#CROSS_ID');
    var start_select = jQuery('select#PORT_START');
    var finish_select = jQuery('select#PORT_FINISH');
    var used_port_ranges = JSON.parse('%USED_PORTS%');

    var get_ports_count_for_cross = function(cross_id){
      var option = cross_select.find('option[value="'+ cross_id +'"]');
      var ports_count = option.data('ports_count');
      if (!ports_count){
        alert('no ports count for cross ' + cross_id);
      }
      return ports_count;
    };

    var fill_with_numeric_options = function(select, range_start, range_finish, cross_id){
      var old_value = select.val();

      // Make disabled ports range
      var disabled_ports = [];
          console.log(cross_id, used_port_ranges[cross_id]);
      if (cross_id && typeof(used_port_ranges[cross_id]) !== 'undefined') {
        for (var i = 0; i < used_port_ranges[cross_id].length; i++) {
          var range_start_end = used_port_ranges[cross_id][i];
          console.log(cross_id, range_start_end);

          for (var j = range_start_end['start']; j <= range_start_end['finish']; j++) {
            disabled_ports[j] = true;
          }
        }
      }

      var options = [];
      for (var i = range_start; i <= range_finish; i++) {
        options.push('<option value="' + i + '" '
            + (disabled_ports[i] ? 'disabled="disabled"' : '')
            + '>' + i + '</option>')
      }
      select.html(options.join(''));
      if (old_value) {
        renewChosenValue(select, old_value);
      }
      else {
        updateChosen();
      }
    };

    var renew_ports_count = function(){
      var cross_id = cross_select.val();
      var ports_count = get_ports_count_for_cross(cross_id);

      fill_with_numeric_options(start_select, 1, +ports_count - 1, cross_id);
      fill_with_numeric_options(finish_select, 2, ports_count, cross_id);
    };

    var align_finish_greater_than_start = function(){
      var start_port_val = start_select.val();
      var cross_id = cross_select.val();
      var max_count = get_ports_count_for_cross(cross_id);
      fill_with_numeric_options(finish_select, +start_port_val + 1, max_count, cross_id);
    };

    cross_select.on('change', renew_ports_count);
    start_select.on('change', align_finish_greater_than_start);

    renew_ports_count();
  });
</script>