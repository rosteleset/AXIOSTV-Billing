<script>
  jQuery(document).ready(function () {
    //find NAS_TYPE Select
    var typeSelect = jQuery('#NAS_TYPE');

    //find wiki-link button '?'
    var wikiLink = jQuery('#wiki-link');

    //get base url from wiki-link
    var wiki_NAS_Href = wikiLink.attr('href');

    //define handler for select
    //here we need to change href link regarding to selected option
    typeSelect.on('change', function () {

      wikiLink.fadeToggle();
      wikiLink.fadeToggle();
      var selected = typeSelect.val();
      wikiLink.attr('href', wiki_NAS_Href + ':' + selected + ':ru');
    });
  });
</script>

<form action=%SELF_URL% METHOD=post name=FORM_NAS>
  <input type=hidden name='index' value='62'>
  <input type=hidden name='NAS_ID' value='%NAS_ID%'>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4 class='card-title'>_{NAS}_</h4></div>
        <div class='card-body'>

          <div class='form-group row'>
            <label class='col-md-3 control-label required' for='NAS_IP'>IP:</label>
            <div class='col-md-9'>
              <input type=text class='form-control ip-input' required id='NAS_IP'
                     placeholder='%IP%' name='IP' value='%NAS_IP%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label required' for='NAS_NAME'>_{NAME}_:</label>
            <div class='col-md-9'>
              <input type='text' class='form-control' id='NAS_NAME' placeholder='%NAS_NAME%'
                     name='NAS_NAME' value='%NAS_NAME%' required pattern='^\\w*\$' maxlength='30'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label required' for='NAS_TYPE'>_{TYPE}_:</label>
            <div class='col-md-9'>

              <div class='d-flex bd-highlight' id='NAS-type-wrapper'>
                <div class='flex-fill bd-highlight'>
                  <div class='select'>
                    <div class='input-group-append select2-append'>
                      %SEL_TYPE%
                    </div>
                  </div>
                </div>
                <div class='bd-highlight'>
                  <div class='input-group-append h-100'>
                    <a id='wiki-link' class='btn input-group-button rounded-left-0' data-tooltip='_{GUIDE_WIKI_LINK}_'
                       href='https://wiki.billing.axiostv.ru/?epkb_post_type_1_category=настройка-серверов-доступа' target='_blank'>?</a>
                    %WINBOX%
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for='NAS_ALIVE'>Alive (sec.):</label>
            <div class='col-md-9'>
              <input class='form-control' id='NAS_ALIVE' placeholder='%NAS_ALIVE%' name='NAS_ALIVE'
                     value='%NAS_ALIVE%'>
            </div>
          </div>

          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='NAS_DISABLE' name='NAS_DISABLE'
                   %NAS_DISABLE% value='1'>
            <label for='NAS_DISABLE' class='custom-control-label'>_{DISABLE}_</label>
          </div>

          <div class='form-row'><label class='col-md-12 bg-primary'>_{MANAGE}_</label></div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for='NAS_MNG_IP'>IP:</label>
            <div class='col-md-4'>
              <input id='NAS_MNG_IP' name='NAS_MNG_IP' value='%NAS_MNG_IP%'
                     placeholder='IP' class='form-control' type='text'>
            </div>

            <label class='col-md-2 control-label' for='COA_PORT'>POD/COA:</label>
            <div class='col-md-3'>
              <input id='COA_PORT' name='COA_PORT' value='%COA_PORT%'
                     placeholder='PORT' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for='SSH_PORT'>SSH:</label>
            <div class='col-md-4'>
              <input id='SSH_PORT' name='SSH_PORT' value='%SSH_PORT%'
                     placeholder='PORT' class='form-control' type='text'>
            </div>

            <label class='col-md-2 control-label' for='SNMP_PORT'>SNMP:</label>
            <div class='col-md-3'>
              <input id='SNMP_PORT' name='SNMP_PORT' value='%SNMP_PORT%'
                     placeholder='PORT' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for='NAS_MNG_USER'>_{USER}_:</label>
            <div class='col-md-9'>
              <div class='input-group'>
                <input id='NAS_MNG_USER' name='NAS_MNG_USER' value='%NAS_MNG_USER%'
                       placeholder='%NAS_MNG_USER%'
                       class='form-control' type='text'>
                <div class='input-group-append'>
                  <a href='$SELF_URL?qindex=$index&NAS_ID=%NAS_ID%&create=1&ssh_key=1'
                     class='btn input-group-button' target='_new' title='_{CREATE}_ SSH public key'>
                    <i class='fa fa-key'></i>
                  </a>
                  <a href='$SELF_URL?qindex=$index&NAS_ID=%NAS_ID%&download=1&ssh_key=1'
                     class='btn input-group-button' target='_new' title='_{DOWNLOAD}_ SSH public key'>
                    <i class='fa fa-download'></i>
                  </a>

                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for='NAS_MNG_PASSWORD'>_{PASSWD}_ (PoD, RADIUS Secret, SNMP
              community):</label>
            <div class='col-md-9'>
              <div class='input-group'>
                <input id='NAS_MNG_PASSWORD' name='NAS_MNG_PASSWORD' class='form-control' autocomplete='new-password'
                       type='password'>
              </div>
            </div>
          </div>

          <div class='form-group'>
            %ADDRESS_FORM%
          </div>
        </div>
      </div>
    </div>

    <div class='col-md-6'>
      <div class='form-group'>
        <div class='card card-primary card-outline card-form-big collapsed-card'>
          <div class='card-header with-border'>
            <h4 class='card-title'>_{EXTRA}_</h4>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div id='nas_misc' class='card-collapse card-body collapse in'>
            %NAS_ID_FORM%

            <div class='form-group row'>
              <label class='col-md-3 control-label' for='NAS_DESCRIBE'>_{DESCRIBE}_:</label>
              <div class='col-md-9'>
                <div class='input-group'>
                  <input class='form-control' id='NAS_DESCRIBE' placeholder='%NAS_DESCRIBE%' name='NAS_DESCRIBE'
                         value='%NAS_DESCRIBE%'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-3 control-label' for='NAS_IDENTIFIER'>Radius NAS-Identifier:</label>
              <div class='col-md-9'>
                <div class='input-group'>
                  <input id='NAS_IDENTIFIER' name='NAS_IDENTIFIER' value='%NAS_IDENTIFIER%'
                         placeholder='%NAS_IDENTIFIER%' class='form-control' type='text'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-3 control-label' for='MAC'>MAC:</label>
              <div class='col-md-9'>
                <div class='input-group'>
                  <input id='MAC' name='MAC' value='%MAC%' placeholder='%MAC%' class='form-control' type='text'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-3 control-label' for='AUTH_TYPE'>_{AUTH}_:</label>
              <div class='col-md-9'>
                <div class='input-group'>
                  %SEL_AUTH_TYPE%
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-3 control-label' for='EXT_ACCT'>Ext. Accounting:</label>
              <div class='col-md-9'>
                <div class='input-group'>
                  %NAS_EXT_ACCT%
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-3 control-label' for='NAS_GROUPS'>_{GROUP}_:</label>
              <div class='col-md-9'>
                %NAS_GROUPS_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-3 control-label' for='ZABBIX_HOSTID'>Zabbix hostid:</label>
              <div class='col-md-9'>
                <div class='input-group'>
                  <input id='ZABBIX_HOSTID' name='ZABBIX_HOSTID' value='%ZABBIX_HOSTID%' class='form-control'
                         type='text'>
                </div>
              </div>
            </div>

            %RAD_PAIRS_FORM%

            <div>
              %EXTRA_PARAMS%
            </div>
          </div>
        </div>
      </div>

    </div>
    <div class='col-md-12'>
      <div class='card-footer'>
        <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
      </div>
    </div>
  </div>
</form>
