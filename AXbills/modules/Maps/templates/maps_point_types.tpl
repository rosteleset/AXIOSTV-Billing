<form name='MAPS_POINT_TYPES_FORM' id='form_MAPS_POINT_TYPES_FORM' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='chg' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{OBJECT}_: _{TYPE}_</h4></div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='NAME'>_{NAME}_: </label>
        <div class='col-md-9'>
          <input type='text' disabled class='form-control' value='%NAME%' required name='NAME' id='NAME'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='ICON_SELECT'>_{ICON}_: </label>
        <div class='col-md-9'>
          <div class='d-flex bd-highlight'>
            <div class='p-2 bd-highlight' id='DIV_ICON'></div>
            <div class='p-2 flex-fill bd-highlight' id='DIV_SELECT'>%ICON_SELECT%</div>
            <div class='p-2 flex-fill bd-highlight'>%UPLOAD_BTN%</div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_: </label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='change' value='_{CHANGE}_'>
    </div>
  </div>

</form>

<script>
  jQuery(document).ready(function () {
    let icon_select = jQuery('#ICON_SELECT');
    jQuery('#DIV_ICON').html('<img style="max-width: 100px" src="/images/maps/icons/' + icon_select.val() + '.png"/>');

    icon_select.on('change', function () {
      jQuery('#DIV_ICON').html('<img style="max-width: 100px" src="/images/maps/icons/' + icon_select.val() + '.png"/>');
    });

    jQuery('#ajax_upload_submit').on('click', function () {
      setTimeout(function () {
        jQuery('.modal').modal('hide');
      }, 2000);
    });
  });

  function updateIcons(fileName) {
    let selectedIcon = fileName ? fileName : jQuery('#ICON_SELECT').val();
    jQuery.get('$SELF_URL', 'get_index=_maps_icon_filename_select&GET_SELECT=1&header=2&ICON=' + selectedIcon, function (result) {
      if (result.match("<select")){
        jQuery('#DIV_SELECT').html(result);
        initChosen();

        jQuery('#DIV_ICON').html('<img style="max-width: 100px" src="/images/maps/icons/' + selectedIcon + '.png"/>');
        jQuery('#ICON_SELECT').on('change', function () {
          jQuery('#DIV_ICON').html('<img style="max-width: 100px" src="/images/maps/icons/' + jQuery('#ICON_SELECT').val() + '.png"/>');
        });
      }
    });
  }
</script>
