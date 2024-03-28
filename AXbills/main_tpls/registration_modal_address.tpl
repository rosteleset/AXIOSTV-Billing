<div class='form-address' style="padding-left: 10px">
  <input type='hidden' name='LOCATION_ID' id="LOCATION_ID_REG" value='%LOCATION_ID%' class='HIDDEN-BUILD'>

  <div class='form-group' style='%EXT_SEL_STYLE%'>
    <label class='control-label col-xs-3 col-md-2 LABEL-DISTRICT'>_{DISTRICTS}_</label>
    <div class='col-xs-9 col-md-10'>
      %ADDRESS_DISTRICT%
    </div>
  </div>
  <div class='form-group' style='%EXT_SEL_STYLE%'>
    <label class='control-label col-xs-3 col-md-2 LABEL-STREET'>_{ADDRESS_STREET}_</label>
    <div class='col-xs-9 col-md-10' id="registration_streets">
      %ADDRESS_STREET%
    </div>
  </div>

  <div class='form-group' style='%EXT_SEL_STYLE%'>
      <label class='control-label col-xs-3 col-md-2 LABEL-BUILD'>_{ADDRESS_BUILD}_</label>
        <div id="registration_builds" class="col-xs-9 col-md-10" >
          %ADDRESS_BUILD%
        </div>
  </div>

</div>

<script>
  jQuery(function () {
    // Updating streets and builds
    var distName_reg = jQuery('#select2-REG_DISTRICT_ID-container.select2-selection__rendered').text();
    var strName_reg = jQuery('#select2-REG_STREET_ID-container.select2-selection__rendered').text();
    var buildName_reg = jQuery('#select2-REG_BUILD_ID-container.select2-selection__rendered').text();
    setInterval(function () {
      var newD_reg = jQuery('#select2-REG_DISTRICT_ID-container.select2-selection__rendered').text();
      var newS_reg = jQuery('#select2-REG_STREET_ID-container.select2-selection__rendered').text();
      var newB_reg = jQuery('#select2-REG_BUILD_ID-container.select2-selection__rendered').text();
      //Get streets after change district
      if (distName_reg !== newD_reg) {
        GetStreets_reg();
        distName_reg = newD_reg;
      }
      //Get builds after change street
      if (strName_reg !== newS_reg) {
        GetBuilds_reg();
        strName_reg = newS_reg;
      }
      //Get location_id after change build
      if (buildName_reg !== newB_reg) {
        GetLoc_reg();
        buildName_reg = newB_reg;
      }
    }, 1000);
  });

  function GetStreetsREG_DISTRICT_ID(data) {
    var d = jQuery("#REG_DISTRICT_ID").val();
    // console.log(d);
    jQuery.post('$SELF_URL', 'header=2&get_index=form_address_select2&DISTRICT_ID=' + d + '&STREET=1&REGISTRATION_MODAL=1', function (result) {
      jQuery('#registration_streets').html(result);
      initChosen();
    });
  }
  function GetBuildsREG_STREET_ID(data) {
    var s = jQuery("#REG_STREET_ID").val();
    // console.log(s);
    jQuery.post('$SELF_URL', 'header=2&get_index=form_address_select2&STREET_ID='+s+'&BUILD=1&REGISTRATION_MODAL=1', function (result) {
      jQuery('#registration_builds').html(result);
      initChosen();
    });
  }
  //Get location_id after change build
  function GetLocREG_BUILD_ID(data) {
    var i = jQuery("#REG_BUILD_ID").val();
    if (i == "--") {
      i = '';
    }
    jQuery('#LOCATION_ID_REG').attr('value', i);
  };

</script>
