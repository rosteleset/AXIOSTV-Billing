<form action=$SELF_URL class='form-horizontal'>
  <input type=hidden name=index value=$index>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{AUTO_COORDS}_</h4></div>
    <div class='card-body'>
      <div class='form-address'>
        <input type='hidden' name='LOCATION_ID' id='ADD_LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

        <div class='form-group row' style='%EXT_SEL_STYLE%'>
          <label class='col-md-4 col-form-label text-md-right LABEL-DISTRICT'>_{DISTRICTS}_</label>
          <div class='col-md-8'>
            %DISTRICTS_SELECT%
          </div>
        </div>

        <div class='form-group row' style='%EXT_SEL_STYLE%'>
          <label class='col-md-4 col-form-label text-md-right LABEL-DISTRICT'>_{STREETS}_</label>
          <div class='col-md-8'>
            %STREETS_SELECT%
          </div>
        </div>

      </div>
    </div>
    <div class='card-footer'>
      <input id='GMA_EXECUTE_BTN' type=submit name=discovery value='_{START}_' class='btn btn-primary'>
    </div>
  </div>
</form>

<script>

  const NOT_FOUND       = '_{COORDS_NOT_FOUND}_' || 'Not found';
  const SUCCESS         = '_{SUCCESS}_' || 'Success';
  const SEVERAL_RESULTS = '_{SEVERAL_RESULTS}_' || 'Several results';

  const streetId = jQuery('#STREET_ID');

  function GetStreets(data) {
    const districtId = jQuery("#" + data.id).val();
    jQuery.post('$SELF_URL', getUrl(districtId ? districtId : '_SHOW'), function (result) {
      streetId.html(result);
      streetId.focus();
      streetId.select2('open');
    });
  }

  function getUrl(districtId) {
    return '%QINDEX%header=2&get_index=form_address_select2&DISTRICT_ID=' + districtId
    + '&STREET=1&DISTRICT_SELECT_ID=%DISTRICT_ID%&STREET_SELECT_ID=%STREET_ID%&BUILD_SELECT_ID=%BUILD_ID%';
  }
</script>

<script src='/styles/default/js/maps/location-search.js'></script>