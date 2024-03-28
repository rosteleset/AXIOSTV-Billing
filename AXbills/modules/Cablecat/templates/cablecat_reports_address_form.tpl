<div class="well well-sm">
  <div class="row ">
    <div class="col-md-3">
      <p class='form-control-static'><strong>_{ADDRESS}_</strong></p>
    </div>
    <div class="col-md-9">
      <div class='form-address form form-horizontal'>
        <input type='hidden' form='%FORM_ID%' name='DISTRICT_ID' value='%DISTRICT_ID%' class='HIDDEN-DISTRICT'>
        <input type='hidden' form='%FORM_ID%' name='STREET_ID' value='%STREET_ID%' class='HIDDEN-STREET'>
        <input type='hidden' form='%FORM_ID%' name='LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

        <div class='form-group'>

          <div class='col-xs-12 col-md-4'>
            <select name='ADDRESS_DISTRICT' form='%FORM_ID%' class='form-control SELECT-DISTRICT'
                    data-fieldname='DISTRICT' data-download-on-click='1'>
              <option value=''></option>
              <option value='%DISTRICT_ID%' selected>%ADDRESS_DISTRICT%</option>
            </select>
          </div>

          <div class='col-xs-12 col-md-4'>
            <select name='ADDRESS_STREET' class='form-control SELECT-STREET'
                    data-fieldname='STREET' form='%FORM_ID%' data-download-on-click='1'>
              <option value=''></option>
              <option value='%STREET_ID%' selected>%ADDRESS_STREET%</option>
            </select>
          </div>

          <div class='col-xs-12 col-md-4'>
            <select name='ADDRESS_BUILD' form='%FORM_ID%' class='form-control SELECT-BUILD'
                    data-fieldname='BUILD' data-download-on-click='1'>
              <option value=''></option>
              <option value='%ADDRESS_BUILD%' selected>%ADDRESS_BUILD%</option>
            </select>


          </div>
        </div>


      </div>

    </div>
  </div>
</div>
<script src='/styles/default/js/searchLocation.js'></script>

