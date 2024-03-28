<script>
  if (typeof LANG === 'undefined') LANG = {};
  LANG['PORT_TYPE'] = '_{PORT_TYPE}_';
  LANG['EXTRA_PORT'] = '_{EXTRA_PORT}_';
  LANG['ROW_NUMBER'] = '_{ROW_NUMBER}_';
  LANG['COMBO_PORT'] = '_{COMBO_PORT}_';
</script>

<script src='/styles/default/js/modules/equipment.js'></script>

<FORM action='%SELF_URL%' METHOD='POST' class='form-horizontal' id='EQUIPMENT_MODEL_INFO_FORM'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='$FORM{chg}'>
  <input type='hidden' name='chg' value='$FORM{chg}'>
  <input type='hidden' name='HAS_EXTRA_PORTS' id='HAS_EXTRA_PORTS'>

    <div class='card card-primary card-outline container-md'>
      <div class='card-header with-border'>
        <h4 class="card-title">_{EQUIPMENT}_ _{INFO}_</h4>
      </div>
      <div class='card-body'>

        %EQUIPMENT_IMAGE%

        <div class='form-group row'>
          <label  class='col-md-4 col-form-label text-md-right' for='TYPE_ID'>_{TYPE}_:</label>
          <div class='col-md-8'>
            %TYPE_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='VENDOR_ID'>_{VENDOR}_:</label>
          <div class='col-md-8'>
            %VENDOR_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-4 col-form-label text-md-right' for='MODEL_NAME'>_{MODEL}_:</label>
          <div class='col-md-8'>
            <input type=text class='form-control' id='MODEL_NAME' placeholder='%MODEL_NAME%'
              name='MODEL_NAME' value='%MODEL_NAME%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-4 col-form-label text-md-right' for='TEST_FIRMWARE'>_{FIRMWARE}_:</label>
          <div class='col-md-8'>
            <input type=text class='form-control' id='TEST_FIRMWARE' placeholder='%TEST_FIRMWARE%' name='TEST_FIRMWARE'
              value='%TEST_FIRMWARE%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-4 col-form-label text-md-right' for='SITE'>URL:</label>
          <div class='col-md-8'>
            <div class="input-group">
              <input class='form-control' type='text' id='SITE' name='SITE' value='%SITE%'>
              <div class="input-group-append">
                <div class='input-group-text'>
                  <a title='_{GO}_' href='%SITE%' target='%SITE%'>_{GO}_</a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-4 col-form-label text-md-right' for='IMAGE_URL'>_{IMAGE_URL}_:</label>
          <div class='col-md-8'>
            <input type='text' class='form-control' id='IMAGE_URL' placeholder='%IMAGE_URL%'
              name='IMAGE_URL' value='%IMAGE_URL%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-4 col-form-label text-md-right' for='ELECTRIC_POWER'>_{ELECTRIC_POWER}_:</label>
          <div class='col-md-8'>
            <input type=number class='form-control' id='ELECTRIC_POWER' placeholder='%ELECTRIC_POWER%'
              name='ELECTRIC_POWER' value='%ELECTRIC_POWER%'>
          </div>
        </div>

        <div class='card card-default collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{MANAGE}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='MANAGE_WEB'>WEB:</label>
              <div class='col-md-8'>
                <input class='form-control' type='text' id='MANAGE_WEB' name='MANAGE_WEB' value='%MANAGE_WEB%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='MANAGE_SSH'>Telnet/SSH:</label>
              <div class='col-md-8'>
                <input class='form-control' type='text' name='MANAGE_SSH' id='MANAGE_SSH' value='%MANAGE_SSH%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='SNMP_TPL'>_{SNMP_SURVEY}_:</label>
              <div class='col-md-8'>
                %SNMP_TPL_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='SYS_OID'>SYSTEM_OID:</label>
              <div class='col-md-8'>
                <input class='form-control' type='text' id='SYS_OID' name='SYS_OID' value='%SYS_OID%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
              <div class='col-md-8'>
                <textarea class='form-control' name='COMMENTS' id='COMMENTS' rows='6'
                  cols='50'>%COMMENTS%</textarea>
              </div>
            </div>

          </div>
        </div>


        <div class='card box-default collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{PORTS}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='PORT_SHIFT'>_{PORT_SHIFT}_ SNMP:</label>
              <div class='col-md-8'>
                <input class='form-control' type='number' min='0' id='PORT_SHIFT' name='PORT_SHIFT'
                  value='%PORT_SHIFT%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='AUTO_PORT_SHIFT'>_{USE_AUTO_PORT_SHIFT}_ SNMP:</label>
              <div class='col-md-8 p-2'>
                <input type='checkbox' name='AUTO_PORT_SHIFT' value=1 %AUTO_PORT_SHIFT% ID='AUTO_PORT_SHIFT'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='FDB_USES_PORT_NUMBER_INDEX'>_{FDB_USES_PORT_NUMBER_INDEX}_:</label>
              <div class='col-md-8 p-2'>
                <input type='checkbox' name='FDB_USES_PORT_NUMBER_INDEX' value=1 %FDB_USES_PORT_NUMBER_INDEX% ID='FDB_USES_PORT_NUMBER_INDEX'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='PORTS'>_{COUNT}_:</label>
              <div class='col-md-8'>
                <input class='form-control' type='number' min='1' max='300' id='PORTS' name='PORTS' value='%PORTS%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='PORTS_TYPE'>_{PORTS}_ _{TYPE}_:</label>
              <div class='col-md-8'>
                %PORTS_TYPE_SELECT%
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='ROWS_COUNT_id'>_{ROWS}_:</label>
              <div class='col-md-8'>
                <input type='number' min='1' class='form-control' name='ROWS_COUNT' value='%ROWS_COUNT%'
                  id='ROWS_COUNT_id'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='BLOCK_SIZE_id'>_{IN_BLOCK}_:</label>
              <div class='col-md-8'>
                <input type='number' min='1' class='form-control' name='BLOCK_SIZE' value='%BLOCK_SIZE%'
                  id='BLOCK_SIZE_id'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='PORT_NUMBERING'>_{PORT_NUMBERING}_:</label>
              <div class='col-md-8'>
                %PORT_NUMBERING_SELECT%
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='FIRST_POSITION'>_{FIRST_PORT_POSITION}_:</label>
              <div class='col-md-8'>
                %FIRST_POSITION_SELECT%
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='HEIGHT_id'>_{HIEGHT}_, U:</label>
              <div class='col-md-8'>
                <input type='number' class='form-control' name='HEIGHT' value='%HEIGHT%'
                       id='HEIGHT_id'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='WIDTH_id'>_{WIDTH}_, U:</label>
              <div class='col-md-8'>
                <input type='number' class='form-control' name='WIDTH' value='%WIDTH%'
                       id='WIDTH_id'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-md-4 col-form-label text-md-right' for='CONT_NUM_EXTRA_PORTS'>_{CONTINUATION_NUMBERING_FOR_EXTRA_PORTS}_:</label>
              <div class='col-md-8 p-2'>
                <input type='checkbox' name='CONT_NUM_EXTRA_PORTS' value=1 %CONT_NUM_EXTRA_PORTS% ID='CONT_NUM_EXTRA_PORTS'/>
              </div>
            </div>

            <div id='extraPortWrapper'>
              <div id='templateWrapper'>
                %EXTRA_PORT1_SELECT%
              </div>
            </div>

            <div class='form-group' id='extraPortControls'>
              <div class='text-right'>
                <div class='btn-group btn-group-xs'>
                  <button class='btn btn-sm btn-danger' id='removePortBtn'
                      data-tooltip='_{DEL}_ _{PORT}_'
                      data-tooltip-position='bottom'>
                    <span class='fa fa-times'></span>
                  </button>
                  <button class='btn btn-sm btn-success' id='addPortBtn'
                      data-tooltip='_{ADD}_ _{PORT}_'>
                    <span class='fa fa-plus'></span>
                  </button>
                </div>
              </div>
            </div>

          </div>

        </div>

        <div class='card box-default collapsed-card' id='equipmentModelPon' %EQUIPMENT_MODEL_PON_HIDDEN%>
          <div class='card-header with-border'>
            <h3 class='card-title'>PON</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='EPON_SUPPORTED_ONUS'>_{NUMBER_OF_SUPPORTED_ONUS_ON_BRANCH_FOR}_ EPON:</label>
              <div class='col-md-8'>
                <input class='form-control' type='number' min=0 id='EPON_SUPPORTED_ONUS' name='EPON_SUPPORTED_ONUS' value='%EPON_SUPPORTED_ONUS%' %EQUIPMENT_MODEL_PON_DISABLED%>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='GPON_SUPPORTED_ONUS'>_{NUMBER_OF_SUPPORTED_ONUS_ON_BRANCH_FOR}_ GPON:</label>
              <div class='col-md-8'>
                <input class='form-control' type='number' min=0 id='GPON_SUPPORTED_ONUS' name='GPON_SUPPORTED_ONUS' value='%GPON_SUPPORTED_ONUS%' %EQUIPMENT_MODEL_PON_DISABLED%>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='GEPON_SUPPORTED_ONUS'>_{NUMBER_OF_SUPPORTED_ONUS_ON_BRANCH_FOR}_ GEPON:</label>
              <div class='col-md-8'>
                <input class='form-control' type='number' min=0 id='GEPON_SUPPORTED_ONUS' name='GEPON_SUPPORTED_ONUS' value='%GEPON_SUPPORTED_ONUS%' %EQUIPMENT_MODEL_PON_DISABLED%>
              </div>
            </div>
          </div>
        </div>

        <div class='card box-default collapsed-card' id='equipmentModelZte' %EQUIPMENT_MODEL_ZTE_HIDDEN%>
          <div class='card-header with-border'>
            <h3 class='card-title'>ZTE</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='DEFAULT_ONU_REG_TEMPLATE_EPON'>_{DEFAULT_ONU_REG_TEMPLATE}_ (EPON):</label>
              <div class='col-md-8'>
                %DEFAULT_ONU_REG_TEMPLATE_EPON_SELECT%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='DEFAULT_ONU_REG_TEMPLATE_GPON'>_{DEFAULT_ONU_REG_TEMPLATE}_ (GPON):</label>
              <div class='col-md-8'>
                %DEFAULT_ONU_REG_TEMPLATE_GPON_SELECT%
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='card-footer'>
        <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
      </div>
    </div>

  <div class='card card-primary card-outline' id='ports_preview'>
    <div class='card-body'>
      %PORTS_PREVIEW%
    </div>
  </div>


  %EX_INFO%

</FORM>


