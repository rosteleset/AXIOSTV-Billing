<div class='card box-primary'>
    <div class='card-header with-border'><h4 class='card-title'>_{EXPORT}_</h4></div>
    <form name='NETLIST_CALC_EXPORT' id='form_NETLIST_CALC_EXPORT' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='COUNTS' value='$FORM{HOSTS_NUMBER}'/>
        <input type='hidden' name='SUBNET_NETMASK' value='$FORM{SUBNET_MASK}'/>

        <div class='card-body'>
            %EXPORT_TABLE%
            <div class='col-md-8 col-md-push-2'>
                <div class='form-group'>
                    <label class='control-label col-md-5' for='NAME_PREFIX_id'>_{NAME}_ _{PREFIX}_</label>

                    <div class='col-md-7'>
                        <input type='text' class='form-control' name='NAME_PREFIX' value='EXPORT'
                               id='NAME_PREFIX_id'/>

                    </div>
                </div>
            </div>
        </div>
    </form>

    <div class='card-footer'>
        <input type='submit' form='form_NETLIST_CALC_EXPORT' class='btn btn-primary' name='export_pools'
               value='_{EXPORT}_ IP Pools'>
        <input type='submit' form='form_NETLIST_CALC_EXPORT' class='btn btn-primary'  name='export_groups'
               value='_{EXPORT}_ _{GROUPS}_'>
    </div>
</div>

