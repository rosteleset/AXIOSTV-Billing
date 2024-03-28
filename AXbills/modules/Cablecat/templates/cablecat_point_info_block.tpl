<div id='POINT_INFO_BLOCK'>
  <hr/>

<!--  <div class='form-group'>-->
<!--    <div class='col-md-1 col-md-offset-11'>-->
<!--      <a id='point_info_edit_btn' title='_{EDIT}_' target='_blank'>-->
<!--        <span class='fa fa-edit'></span>-->
<!--      </a>-->
<!--    </div>-->
<!--  </div>-->

  <ul class="list-group" style="text-align: left">
    <li class="list-group-item"><b>_{CREATED}_:</b> %CREATED%</li>
    <li class="list-group-item"><b>_{PLANNED}_:</b> %PLANNED_NAMED%</li>
    <li class="list-group-item" data-visible='%SHOW_MAP_BTN%'><b>_{MAP}_:</b> %MAP_BTN%</li>
    <li class="list-group-item"><b>_{ADDRESS}_:</b> %ADDRESS_NAME%</li>
    <li class="list-group-item"><b>_{COMMENTS}_:</b> %COMMENTS%</li>
  </ul>
</div>
<script>
  jQuery(function () {

    var btn = jQuery('#point_info_edit_btn');
    btn.on('click', function () {
      // Load modal
      loadToModal('$SELF_URL?get_index=maps_objects_main&TEMPLATE_ONLY=1&header=2&chg=%ID%');

      // When submitted, renew
      Events.once('AJAX_SUBMIT.form_MAPS_OBJECT', function () {
        aModal.hide();
        jQuery('#POINT_INFO_BLOCK').load(' #POINT_INFO_BLOCK');
      })
    });
  })
</script>
