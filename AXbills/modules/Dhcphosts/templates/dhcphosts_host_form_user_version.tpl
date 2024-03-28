<style type='text/css'>
    .grpstyle {
        margin: 0 0 3px 0;
    }
</style>


%MENU%

<form action='$SELF_URL' METHOD='POST' id='form_host' class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=UID value=$FORM{UID}>
    <input type=hidden name=ID value=$FORM{chg}>
    <input type=hidden name='step' value='$FORM{step}'>

    <fieldset>
            <div class='card card-primary card-outline box-big-form'>

                <div class='card-header with-border text-center'>
                    <h3 class="card-title">DHCP</h3>
                    <div class="card-tools pull-right">
                        <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse"><i
                                class="fa fa-minus"></i>
                        </button>
                    </div>
                </div>
             <!-- Body 1 -->
              <div class='card-body' style="padding: 0">
                <div class='form-group grpstyle'>
                    <label class='control-label col-md-3' for='NETWORKS_SEL'>_{HOSTS_NETWORKS}_:</label>
                    <div class='col-md-9'>
                        %NETWORKS_SEL%
                    </div>
                </div>

                <div class='form-group grpstyle'>
                    <label class='control-label col-md-3' for='IP'>IP:</label>
                    <div class='col-md-9'>
                        <input type='text' id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control'>
                    </div>
                </div>

                <div class='form-group grpstyle'>
                    <label class='control-label col-md-3' for='MAC'>MAC:<BR>(00:00:00:00:00:00)</label>
                    <div class='col-md-9'>
                        <input type='text' id='MAC' name='MAC' value='%MAC%' placeholder='%MAC%' class='form-control'>
                    </div>
                </div>
                    <div class='form-group grpstyle bg-primary'>
                        <label class='col-md-3' for='OPTION_82'>Option 82 </label>
                        <div class='col-md-9'>
                            <input id='OPTION_82' name='OPTION_82' value='1' %OPTION_82% type='checkbox'>
                        </div>
                    </div>

                <div class='form-group grpstyle'>
                    <label class='control-label col-md-3' for='NAS_SEL'>_{SWITCH}_:</label>
                    <div class='col-md-9'>
                        %NAS_SEL%
                    </div>
                </div>

                    <div class='form-group grpstyle'>
                        <label class='control-label col-md-3' for='PORTS'>_{PORT}_ (1,2,5):</label>
                        <div class='col-md-6'>
                            %PORTS%
                        </div>
                    </div>

                    <div class='form-group grpstyle'>
                        <label class='control-label col-md-3' for='VID'>VLAN ID:</label>
                        <div class='col-md-3'>
                            <input type='text' id='VID' name='VID' value='%VID%' placeholder='%VID%'
                                   class='form-control'>
                        </div>

                            <label class='control-label col-md-2' for='SERVER_VID'>Server:</label>
                            <div class='col-md-4'>
                              %VLAN_SEL%
                            </div>
                          </div>


                    <div class='form-group grpstyle'>
                        <label class='control-label col-md-3' for='IPN_ACTIVATE'>_{ACTIVATE}_ IPN:</label>
                        <div class='col-md-3'>
                            <input id='IPN_ACTIVATE' name='IPN_ACTIVATE' value='1' %IPN_ACTIVATE% type='checkbox'>
                            %IPN_ACTIVATE_BUTTON%
                        </div>
                    </div>

                    <div class='form-group grpstyle'>
                        <label class='control-label col-md-3' for='HOSTNAME'>_{HOSTS_HOSTNAME}_:</label>
                        <div class='col-md-9'>
                            <input type='text' id='HOSTNAME' name='HOSTNAME' value='%HOSTNAME%' placeholder='%HOSTNAME%'
                                   class='form-control'>
                        </div>
                    </div>

        <!-- Body 1 -->
            <div class='card box-default box-big-form collapsed-box' style="border-top: 1px solid #d2d6de; border-radius: 0px;margin-bottom: 0px">
                <div class='card-header with-border'>
                    <h3 class="card-title">_{INFO}_</h3>
                    <div class="card-tools pull-right">
                        <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse"><i
                                class="fa fa-plus"></i>
                        </button>
                    </div>
                </div>
                <div class='card-body'>
                   %EQUIPMENT_INFO%
                </div>
            </div>

            <div class='card box-default box-big-form collapsed-box' style="border-top: 1px solid #d2d6de;border-radius: 0px;margin-bottom: 0px"">
                <div class='card-header'>
                    <h3 class="card-title">_{EXTRA}_</h3>
                    <div class="card-tools pull-right">
                        <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse"><i
                                class="fa fa-plus"></i>
                        </button>
                    </div>
                </div>
                <div class='card-body'>
                    <div class='form-group grpstyle'>
                        <label class='control-label col-md-3' for='BOOT_FILE'>_{FILE}_:</label>
                        <div class='col-md-9'>
                            <input type='text' id='BOOT_FILE' name='BOOT_FILE' value='%BOOT_FILE%'
                                   placeholder='%BOOT_FILE%'
                                   class='form-control'>
                        </div>
                    </div>

                    <div class='form-group grpstyle'>
                        <label class='control-label col-md-3' for='NEXT_SERVER'>NEXT HOST:</label>
                        <div class='col-md-9'>
                            <input type='text' id='NEXT_SERVER' name='NEXT_SERVER' value='%NEXT_SERVER%'
                                   placeholder='%NEXT_SERVER%' class='form-control'>
                        </div>
                    </div>

                    <div class='form-group grpstyle'>
                        <label class='control-label col-md-3' for='EXPIRE'>_{EXPIRE}_:</label>
                        <div class='col-md-9'>
                            <input type='text' id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                                   class='form-control'>
                        </div>
                    </div>

                    <div class='form-group grpstyle'>
                        <label class='control-label col-md-3' for='DISABLE'>_{DISABLE}_:</label>
                        <div class='col-md-9'>
                            <input id='DISABLE' name='DISABLE' value='1' %DISABLE% type='checkbox'>
                        </div>
                    </div>


                    <div class='form-group'>
                        <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>
                        <div class='col-md-9'>
                            <input type='text' id='COMMENTS' name='COMMENTS' value='%COMMENTS%'
                                   placeholder='%COMMENTS%'
                                   class='form-control'>
                        </div>
                    </div>
                </div>
            </div>
            </div>
              <div class="card-footer">
        <div class='form-group' style="padding-left: 10px">
                %BACK_BUTTON% <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
        </div>
</div>
            </div>

    </fieldset>
</form>
