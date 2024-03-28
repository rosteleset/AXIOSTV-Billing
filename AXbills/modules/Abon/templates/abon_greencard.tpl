<input type='hidden' name='GREEN_CARD' value='1'>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='CAR_TYPE'>_{ABON_VEHICLE_TYPE}_:</label>
  <div class='col-sm-8 col-md-8'>
    %CAR_TYPE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='ZONE_ID'>_{ABON_ZONE_OF_CITY}_:</label>
  <div class='col-sm-8 col-md-8'>
    %ZONE_ID%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='PERIOD_ID'>_{ABON_DURATION_STAY}_:</label>
  <div class='col-sm-8 col-md-8'>
    %PERIOD_ID%
  </div>
</div>

<script>
  jQuery(document).ready(function () {
    jQuery('#ACCEPT_LICENSE').parent().parent().remove();
  });
</script>
