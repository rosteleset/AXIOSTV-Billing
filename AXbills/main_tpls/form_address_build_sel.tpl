<div class='form-address'>
  <input type='hidden' name='DISTRICT_ID' value='%DISTRICT_ID%' class='HIDDEN-DISTRICT'>
  <input type='hidden' name='STREET_ID' value='%STREET_ID%' class='HIDDEN-STREET'>
  <input type='hidden' name='LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

  <div class='form-group row'>

    <div class='col-xs-12 col-md-4'>
      <select name='ADDRESS_DISTRICT' class='form-control SELECT-DISTRICT w-100'
              data-fieldname='DISTRICT' data-download-on-click='1'>
        <option value='%DISTRICT_ID%' selected>%ADDRESS_DISTRICT%</option>
      </select>
    </div>

    <div class='col-xs-12 col-md-4'>
      <select name='ADDRESS_STREET' class='form-control SELECT-STREET'
              data-fieldname='STREET' data-download-on-click='1'>
        <option value='%STREET_ID%' selected>%ADDRESS_STREET%</option>
      </select>
    </div>

    <div class='col-xs-12 col-md-4'>

      <div class='addBuildMenu'>

        <div class='d-flex bd-highlight'>
          <div class='flex-fill bd-highlight'>
            <div class='select'>
              <div class='input-group-append select2-append'>
                <select name='ADDRESS_BUILD' class='form-control SELECT-BUILD'
                        data-fieldname='BUILD' data-download-on-click='1'>
                  <option value='%ADDRESS_BUILD%' selected>%ADDRESS_BUILD%</option>
                </select>
              </div>
            </div>
          </div>
          <div class='bd-highlight' %HIDE_ADD_BUILD_BUTTON%>
            <div class='input-group-append h-100'>
              <a title='_{ADD}_ _{BUILDS}_' class='btn input-group-button rounded-left-0 BUTTON-ENABLE-ADD'>
                <span class='fa fa-plus'></span>
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class='changeBuildMenu' style='display : none'>
        <div class='input-group'>
          <input type='text' name='ADD_ADDRESS_BUILD' class='form-control INPUT-ADD-BUILD'/>
          <span class='input-group-append'>
            <a class='btn input-group-button rounded-left-0 BUTTON-ENABLE-SEL'>
              <span class='fa fa-list'></span>
            </a>
           </span>
        </div>
      </div>
    </div>
  </div>
</div>

<script src='/styles/default/js/searchLocation.js'></script>

