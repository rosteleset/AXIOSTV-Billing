<div class='d-print-none'>
  <FORM action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='IP_NUM' value='%IP_NUM%'>
    <input type='hidden' name='IP_ID' value='%IP_ID%'>


    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'>%ACTION_LNG%</div>
      <div class='card-body'>
        <div class='form-group'>
          <a class='col-md-6 float-right' href='index.cgi?index=%IP_SCAN_INDEX%'>_{SCAN}_ <span
              class='fa fa-search'></span></a>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>IP:</label>

          <div class='col-md-9'>
            <input id='IP' class='form-control ip-input' type='text' name='IP' value='%IP%'/>
          </div>
        </div>
        <div class='form-group' id='ip-netmask'>
          <label class='col-md-3 control-label'>NETMASK:</label>

          <div class='col-md-9'>
            <input id='NETMASK' class='form-control' type='text' name='NETMASK' value='%NETMASK%'/>
          </div>
        </div>
        <div class='form-group' id='ip-prefix' style='display: none'>
          <label class='col-md-5 control-label'>IPv6 _{PREFIX}_:</label>

          <div class='col-md-7'>
            <input id='IPV6_PREFIX' class='form-control' type='text' name='IPV6_PREFIX' value='%IPV6_PREFIX%'/>
          </div>
        </div>
        <hr>
        <div class='form-group'>
          <label class='col-md-3 control-label'>MAC:</label>

          <div class='col-md-9'>
            <input class='form-control' type='text' name='MAC' value='%MAC%'/>
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-7 control-label'>_{AUTO_DETECT}_ MAC:</label>

          <div class='col-md-5'>
            <input type='checkbox' class='control-element' name='MAC_AUTO_DETECT' value='1'
                   %MAC_AUTO_DETECT%/>
          </div>
        </div>
        <hr>
        <div class='form-group'>
          <label class='col-md-3 control-label'>HOSTNAME (FQDN):</label>

          <div class='col-md-9'>
            <input class='form-control' type='text' name='HOSTNAME' value='%HOSTNAME%'/>
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{DESCRIBE}_:</label>

          <div class='col-md-9'>
            <input class='form-control' type='text' name='DESCR' value='%DESCR%'/>
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{GROUP}_: </label>

          <div class='col-md-9'>%GROUP_SEL%</div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{STATE}_:</label>

          <div class='col-md-9'>%STATE_SEL%</div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{PHONE}_:</label>

          <div class='col-md-9'>
            <input class='form-control' type='text' name='PHONE' value='%PHONE%'/>
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>E-Mail:</label>

          <div class='col-md-9'>
            <input class='form-control' type='text' name='EMAIL' value='%EMAIL%'/>
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{COMMENTS}_:</label>

          <div class='col-md-9'>
                        <textarea class='form-control' name='COMMENTS' rows='6'
                                  cols='60'>%COMMENTS%</textarea>
          </div>
        </div>
      </div>

      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' name='%ACTION%' value='%ACTION_LNG%'>
      </div>
    </div>
  </FORM>
</div>

<script src='/styles/default/js/modules/netlist/ipv4.js'></script>

<script>
  jQuery(function () {

    //cache DOM
    var ipInput     = jQuery('#IP');
    var maskInput   = jQuery('#NETMASK');
    var prefixInput = jQuery('#IPV6_PREFIX');

    var maskInputGroup   = maskInput.parent().parent();
    var prefixInputGroup = prefixInput.parent().parent();


    //**bind events

    //check for correct mask input
    var netmaskPattern = "(255|254|252|248|240|224|192|128|0)[.](255|254|252|248|240|224|192|128|0)[.](255|254|252|248|240|224|192|128|0)[.](255|254|252|248|240|224|192|128|0)";
    maskInput.attr('data-check-for-pattern', netmaskPattern);
    defineCheckPatternLogic();

    //if ip is v6 hide netmask input and show prefix
    var maskValue   = ipInput.val() || '';
    var prefixValue = maskInput.val() || '';

    ipInput.on('input', function () {
      checkIPInputType(this.value);
    });

    function checkIPInputType(value) {
      if (value !== '' && isValidIp(value)) {
        if (!isValidIpv4(value)) {
          maskValue = maskInput.val();
          maskInputGroup.hide(200);
          maskInput.val('');

          prefixInputGroup.show(200);
          prefixInput.val(prefixValue);
        } else {
          prefixValue = prefixInput.val();
          prefixInputGroup.hide(200);
          prefixInput.val('');

          maskInputGroup.show(200);
          maskInput.val(prefixValue);
        }
      }
    }

    //Init
    checkIPInputType(ipInput.val());
  });
</script>

