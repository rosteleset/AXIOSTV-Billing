<FORM action=$SELF_URL method='get' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='SUBNET_MASK' id='SUBNET_MASK' value='%SUBNET_MASK%'>
    <input type='hidden' name='MASK' id='MASK_INPUT'>

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'>IP _{CALCULATOR}_</div>

        <div class='card-body'>
            <div class='form-group'>
                <label class='col-md-3 control-label'>IP:</label>

                <div class='col-md-9 inputs-wrapper'>
                    <div class='col-md-3'>
                        <input class='inputs form-control'
                               type='text' maxlength='3' required pattern='[0-9]{1,3}'
                               id='i1' name='IP_D1' value='%IP_D1%'>
                    </div>
                    <div class='col-md-3'>
                        <input class='inputs form-control'
                               type='text' maxlength='3' required pattern='[0-9]{1,3}'
                               id='i2' name='IP_D2' value='%IP_D2%'>
                    </div>
                    <div class='col-md-3'>
                        <input class='inputs form-control'
                               type='text' maxlength='3' required pattern='[0-9]{1,3}'
                               id='i3' name='IP_D3' value='%IP_D3%'>
                    </div>
                    <div class='col-md-3'>
                        <input class='inputs form-control'
                               type='text' maxlength='3' required pattern='[0-9]{1,3}'
                               id='i4' name='IP_D4' value='%IP_D4%'>
                    </div>
                </div>
            </div>

            <hr>

            <div class='form-group' id='ipv4_mask_bits'>
                <label class='col-md-5 control-label'>_{PREFIX}_ _{LENGTH}_:</label>

                <div class='col-md-7'>%MASK_BITS_SEL%</div>

            </div>
            <div class='form-group'>
                <label class='col-md-5 control-label'>_{SUBNET_MASK}_:</label>
              <p class="col-md-7 form-control-static"  id='ipv4_mask'></p>
            </div>

            <hr>

            <div class='form-group' id='subnet_count'>
                <label class='col-md-5 control-label'>_{SPLIT_TO}_:</label>

                <div class='col-md-7'>%SUBNET_NUMBER_SEL%</div>
            </div>

            <div class='form-group' id='hosts_count'>
                <label class='col-md-5 control-label'>_{HOSTS_PER_SUBNET}_:</label>

                <div class='col-md-7'>%HOSTS_NUMBER_SEL%</div>
            </div>
        </div>

        <div class='card-footer'>
            <input class='btn btn-primary' type='submit' name='SHOW' value='_{SHOW}_'>
        </div>
    </div>

</FORM>

<script>
    var _FORM = {
        SUBNET_NUMBER : '$FORM{SUBNET_NUMBER}',
        HOSTS_COUNT : '$FORM{HOSTS_NUMBER}'
    };
</script>


<script src='/styles/default/js/modules/netlist/ipv4.js'></script>

