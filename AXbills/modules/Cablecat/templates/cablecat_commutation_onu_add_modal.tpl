<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>ONU : %WELL%</h4></div>
  <div class='card-body'>
    <form name='CABLECAT_COMMUTATION_ADD_ONU_MODAL' id='CABLECAT_COMMUTATION_ADD_ONU_MODAL' method='post'
          class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='operation' value='ADD'/>
      <input type='hidden' name='entity' value='ONU'/>
      <input type='hidden' name='COMMUTATION_ID' value='%COMMUTATION_ID%'/>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{USER}_:</label>
        <div class='col-md-8'>
          %USER_SELECT%
        </div>
      </div>

      <div class='form-group row' id="SERVICE_SELECT">
      </div>


    </form>

  </div>

  <div class='card-footer'>
    <input type='submit' form='CABLECAT_COMMUTATION_ADD_ONU_MODAL' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>

</div>
<script>
  jQuery(function () {

    jQuery('#UID').change(function () {
      jQuery("#SERVICE_SELECT").html("");

      var val = jQuery('#UID').val();
      if(val == 0) return;

      jQuery("#SERVICE_SELECT").html("<span class='offset-6 fa fa-spin fa-spinner'></span>");

      jQuery.ajax({
        url: '/admin/index.cgi?qindex=$index&header=2&entity=ONU&operation=ADD&COMMUTATION_ID=%COMMUTATION_ID%&getServices=1&UID='+val,
        type: 'GET',
        contentType: false,
        cache: false,
        processData: false,
        success: function (result) {
          jQuery("#SERVICE_SELECT").html("<label class='control-label col-md-4'>_{SERVICE}_:</label>" +
            "<div class='col-md-8'>" +
            result+
            "</div>");
          initChosen();
        },
        fail: function (error) {
          aTooltip.displayError(error);
        },
      });
    });

    jQuery('#CABLECAT_COMMUTATION_ADD_ONU_MODAL').on('submit', ajaxFormSubmit);

    Events.off('AJAX_SUBMIT.CABLECAT_COMMUTATION_ADD_ONU_MODAL');
    Events.once('AJAX_SUBMIT.CABLECAT_COMMUTATION_ADD_ONU_MODAL', function (response) {
      if (response.MESSAGE_ONU_ADDED) {
        aTooltip.displayMessage(response.MESSAGE_ONU_ADDED, 2000);
        location.reload();
      }
    });
  });
</script>