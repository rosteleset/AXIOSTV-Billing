<form name='CHOOSE_IP_ADD_FORM' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='NETMASK' id='MASK_INPUT' value='%SUBNET_MASK%'>
  <input type='hidden' name='IP' value='$FORM{IP}'>
  <input type='hidden' name='ADD' value='1'>


  <div class='card card-primary card-outline'>
    <div class='card-body'>
      <div class='row'>
        %SCAN_TABLE%
      </div>


      <div class='col-md-6 col-md-push-3 box-form'>
        <div class='form-group' id='ipv4_mask_bits'>
          <label class='col-md-5 control-label'>_{PREFIX}_ _{LENGTH}_:</label>

          <div class='col-md-7'>%MASK_BITS_SEL%</div>
        </div>

        <div class='form-group'>
          <label class='col-md-5 control-label'>_{SUBNET_MASK}_:</label>
          <label class='col-md-7 text-muted text-center' id='ipv4_mask'></label>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='action' value='_{ADD}_'/>
    </div>
  </div>
</form>

<script>
  var _FORM = {
    SUBNET_NUMBER: '$FORM{SUBNET_NUMBER}',
    HOSTS_COUNT  : '$FORM{HOSTS_NUMBER}'
  };
</script>

<script src='/styles/default/js/modules/netlist/ipv4.js'></script>