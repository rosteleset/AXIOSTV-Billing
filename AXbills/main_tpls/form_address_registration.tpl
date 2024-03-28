<div class='form-address'>
  <input type='hidden' name='DISTRICT_ID' value='%DISTRICT_ID%' class='HIDDEN-DISTRICT'>
  <input type='hidden' name='STREET_ID' value='%STREET_ID%' class='HIDDEN-STREET'>
  <input type='hidden' name='LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

  <div class='form-group'>
    <label class='control-label col-xs-3 col-md-2 LABEL-DISTRICT'>_{DISTRICTS}_</label>
    <div class='col-xs-9 col-md-10'>
      <select data-download-on-click='1' name='ADDRESS_DISTRICT' class='form-control SELECT-DISTRICT' data-fieldname='DISTRICT'>
        <option value='%DISTRICT_ID%' selected>%ADDRESS_DISTRICT%</option>
      </select>
    </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-xs-3 col-md-2 LABEL-STREET'>_{ADDRESS_STREET}_</label>
    <div class='col-xs-9 col-md-10'>
      <select data-download-on-click='1' name='ADDRESS_STREET' class='form-control SELECT-STREET' data-fieldname='STREET'>
        <option value='%STREET_ID%' selected>%ADDRESS_STREET%</option>
      </select>
    </div>
    %ADDRESS_STREET2%
  </div>

  <div class='form-group'>
    <label class='control-label col-xs-3 col-md-2 LABEL-BUILD'>_{ADDRESS_BUILD}_</label>
    <div class='col-xs-9 col-md-4 addBuildMenu'>

      <div class='input-group'>
        <select data-download-on-click='1' name='ADDRESS_BUILD' class='form-control SELECT-BUILD' data-fieldname='BUILD'>
          <option value='%LOCATION_ID%' selected>%ADDRESS_BUILD%</option>
        </select>

        <!-- Control for toggle build mode SELECT/ADD -->
        <span class='input-group-addon'>
          <a title='_{ADD}_ _{BUILDS}_' class='BUTTON-ENABLE-ADD'>
            <span class='fa fa-plus'></span>
          </a>
        </span>

      </div>
    </div>

    <div class='col-xs-9 col-md-4 changeBuildMenu' style='display : none'>
      <div class='input-group'>
        <input type='text' name='ADD_ADDRESS_BUILD' class='form-control INPUT-ADD-BUILD'/>
        <span class='input-group-addon'>
            <a class='BUTTON-ENABLE-SEL'>
              <span class='fa fa-list'></span>
            </a>
           </span>
      </div>
    </div>


    <label class='control-label col-xs-3 col-md-2'>_{ADDRESS_FLAT}_</label>

    <div class='col-xs-3 col-md-2'>
      <input type='text' name='ADDRESS_FLAT' value='%ADDRESS_FLAT%' class='form-control INPUT-FLAT'>
    </div>

  </div>

</div>

<script>
  document['FLAT_CHECK_FREE']     = '%FLAT_CHECK_FREE%' || false;
  document['FLAT_CHECK_OCCUPIED'] = '%FLAT_CHECK_OCCUPIED%' || false;
</script>
<script src='/styles/default/js/searchLocation.js'></script>

