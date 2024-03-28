<form name='CABLECAT_WELLS_TYPE' id='form_CABLECAT_WELLS_TYPE' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
  <input type='hidden' name='ID' value='%ID%'/>
  
  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>%PANEL_HEADING%</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME_ID'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_ID'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='ICON_SELECT'>_{ICON}_: </label>
        <div class='col-md-8'>
          <div class='d-flex bd-highlight'>
            <div class='p-2 bd-highlight' id='DIV_ICON'></div>
            <div class='p-2 flex-fill bd-highlight' id='DIV_SELECT'>%ICON_SELECT%</div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS_ID'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_ID'>%COMMENTS%</textarea>
        </div>
      </div>
      
    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CABLECAT_WELLS_TYPE' class='btn btn-primary' name='submit'
             value='%SUBMIT_BTN_NAME%'>
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

