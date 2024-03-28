<input type=hidden name=VIEW value=$FORM{VIEW}>

<div class='col-xs-12 col-md-6'>
    <div class='card card-primary card-outline '>
        <div class='card-body'>

            <div class='form-group'>
                <label class='control-label col-md-3' for='HOSTNAME'>_{HOSTS_HOSTNAME}_(*,)</label>
                <div class='col-md-5'>
                    <input id='HOSTNAME' name='HOSTNAME' value='%HOSTNAME%' placeholder='%HOSTNAME%'
                           class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='NETWORKS'>_{HOSTS_NETWORKS}_</label>
                <div class='col-md-9'>
                    %NETWORKS_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='IP'>IP</label>
                <div class='col-md-5'>
                    <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='MAC'>MAC</label>
                <div class='col-md-5'>
                    <input id='MAC' name='MAC' value='%MAC%' placeholder='%MAC%' class='form-control' type='text'>
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-3' for='EXPIRE'>_{EXPIRE}_</label>
                <div class='col-md-5'>
                    <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%' class='form-control'
                           type='text'>
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
                <div class='col-md-5'>
                    %STATUS_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='PORTS'>_{PORT}_</label>
                <div class='col-md-5'>
                    <input id='PORTS' name='PORTS' value='%PORTS%' placeholder='%PORTS%' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='VID'>VLAN _{USER}_:</label>
                <div class='col-md-3'>
                    <input id='VID' name='VID' value='%VID%' placeholder='%VID%' class='form-control' type='text'>
                </div>
                <label class='control-label col-md-3' for='SERVER_VID'>Server:</label>
                <div class='col-md-3'>
                    <input id='SERVER_VID' name='SERVER_VID' value='%SERVER_VID%' placeholder='%SERVER_VID%'
                           class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='NAS'>_{SWITCH}_:</label>
                <div class='col-md-6'>
                    %SWITCH_SEL%
                </div>
            </div>

        </div>
    </div>
</div>