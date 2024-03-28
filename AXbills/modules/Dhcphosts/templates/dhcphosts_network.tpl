<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>_{NETWORKS}_</div>
    <div class='card-body'>
        <form action='$SELF_URL' method='post' class='form-horizontal'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='ID' value='$FORM{chg}'/>


            <div class='form-group'>
                <label for='NAME' class='control-label col-md-4'>_{HOSTS_NETWORKS_NAME}_:</label>
                <div class='col-md-8'>
                    <input type='text' class='form-control' name='NAME' id='NAME' value='%NAME%'/>
                </div>
            </div>

            <div class='form-group'>
                <label for='COMMENTS' class='control-label col-md-4'>_{COMMENTS}_:</label>
                <div class='col-md-8'>
                    <input class='form-control' type='text' name='COMMENTS' id='COMMENTS' value='%COMMENTS%'
                           maxlength='50'/>
                </div>
            </div>

            <div class='form-group'>

                    <label for='NETWORK' class='control-label col-md-2'>_{HOSTS_NETWORKS_NET}_:</label>
                    <div class='col-md-4'>
                        <input type='text' class='form-control' name='NETWORK' id='NETWORK' value='%NETWORK%'
                               maxlength='15'/>
                    </div>

                    <label for='MASK' class='control-label col-md-2'>NETMASK:</label>
                    <div class='col-md-4'>
                        <input type='text' class='form-control' name='MASK' id='MASK' value='%MASK%'
                               maxlength='15'/>
                    </div>

            </div>

            <div class='form-group'>
                <div class='row'>
                    <label class='control-label col-md-2' for='IP_RANGE_FIRST'>IP RANGE:</label>
                    <div class='col-md-4'>
                        <input type='text' class='form-control' name='IP_RANGE_FIRST' id='IP_RANGE_FIRST'
                               value='%IP_RANGE_FIRST%'
                               maxlength='15'/>
                    </div>
                    <label class='col-md-2' for='IP_RANGE_LAST'>_</label>
                    <div class='col-md-4'>
                        <input type='text' class='form-control' name='IP_RANGE_LAST' id='IP_RANGE_LAST'
                               value='%IP_RANGE_LAST%'
                               maxlength='15'/>
                    </div>
                </div>
                </div>

                <div class='form-group'>
                  <div class='checkbox'>
                   <label for='STATIC'>
                    <input type='checkbox' name='STATIC' id='STATIC' value='1' %STATIC%/>
                     <strong>_{STATIC}_</strong>
                    </label>
                 </div>
                </div>

            <div class='form-group'>

                    <label for='ROUTERS' class='control-label col-md-2'>_{DEFAULT_ROUTER}_:</label>
                    <div class='col-md-10'>
                        <input type='text' class='form-control' name='ROUTERS' id='ROUTERS' value='%ROUTERS%'
                               maxlength='15'/>
                    </div>

            </div>
            <div class='form-group'>

                  <label for='DNS' class='control-label col-md-2'>DNS:</label>
                    <div class='col-md-4'>
                        <input type='text' class='form-control' name='DNS' id='DNS' value='%DNS%' maxlength='15'/>
                    </div>
                  <label for='DNS2' class='control-label col-md-2'>DNS2:</label>
                    <div class='col-md-4'>
                        <input type='text' class='form-control' name='DNS2' id='DNS2' value='%DNS2%'
                               maxlength='15'/>
                    </div>

            </div>

            <div class='form-group'>
                <div class='accordion' id='ADVANCED'>
                    <div class='accordion-group'>

                        <div class='accordion-heading'>
                            <a class='accordion-toggle' data-toggle='collapse' data-parent='#ADVANCED'
                               href='#collapseOne'>
                                <button class='btn'> Дополнительно</button>
                            </a>
                        </div>

                        <div id='collapseOne' class='accordion-body collapse well'>
                            <div class='accordion-inner'>
                                <div class='form-group'>
                                    <label for='NTP' class='control-label col-md-3'>NTP:</label>
                                    <div class='col-md-9'>
                                        <input type='text' class='form-control' name='NTP' id='NTP' value='%NTP%'
                                               maxlength='15'/>
                                    </div>
                                </div>

                                <div class='form-group'>
                                    <label for='SUFFIX' class='control-label col-md-3'>DOMAINNAME:</label>
                                    <div class='col-md-9'>
                                        <input type='text' class='form-control' name='SUFFIX' id='SUFFIX'
                                               value='%SUFFIX%'/>
                                    </div>
                                </div>
                                <div class='form-group'>
                                    <label for='DENY_UNKNOWN_CLIENTS' class='control-label col-md-9'>_{DENY_UNKNOWN_CLIENTS}_:</label>
                                    <div class='col-md-3'>
                                        <input type='checkbox' value='1' name='DENY_UNKNOWN_CLIENTS'
                                               id='DENY_UNKNOWN_CLIENTS' %DENY_UNKNOWN_CLIENTS%/>
                                    </div>
                                </div>

                                <div class='form-group'>
                                    <label for='AUTHORITATIVE'
                                           class='control-label col-md-9'>_{AUTHORITATIVE}_:</label>
                                    <div class='col-md-3'>
                                        <input type='checkbox' name='AUTHORITATIVE' id='AUTHORITATIVE' value='1'
                                               %AUTHORITATIVE%/>
                                    </div>
                                </div>

                                <div class='form-group'>
                                    <label for='COORDINATOR' class='control-label col-md-3'>_{HOSTS_NETWORKS_COORDINATOR}_:</label>
                                    <div class='col-md-9'>
                                        <input type='text' class='form-control' name='COORDINATOR' id='COORDINATOR'
                                               value='%COORDINATOR%'/>
                                    </div>
                                </div>

                                <div class='form-group'>
                                    <label for='PHONE' class='control-label col-md-3'>_{HOSTS_NETWORKS_COORDINATOR_PHONE}_:</label>
                                    <div class='col-md-9'>
                                        <input type='text' class='form-control' name='PHONE' id='PHONE'
                                               value='%PHONE%'/>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

                <div class='form-group'>
                  <div class='checkbox'>
                   <label for='STATIC'>
                    <input type='checkbox' name='DISABLE' id='DISABLE' value='1' %DISABLE%/>
                     <strong>_{DISABLE}_</strong>
                    </label>
                 </div>
                </div>

            <div class='form-group'>
                <label class='control-label col-md-2'>_{TYPE}_:</label>

                <div class='col-md-10'>%PARENT_SEL%</div>
            </div>

            <div class='form-group'>
                <div class='row'>
                    <label for='VLAN' class='control-label col-md-2'>VLAN: </label>
                    <div class='col-md-4'>
                        <input type='text' class='form-control' name='VLAN' id='VLAN' value='%VLAN%' maxlength='5'/>
                    </div>
                    <label for='GUEST_VLAN' class='control-label col-md-2'>GUEST VLAN: </label>
                    <div class='col-md-4'>
                        <input type='text' class='form-control' name='GUEST_VLAN' id='GUEST_VLAN' value='%GUEST_VLAN%'
                               maxlength='5'/>
                    </div>
                </div>
            </div>

            %DOMAIN_FORM%

    </div>
        <div class='card-footer'>
            <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'/>
          </div>
     </form>


</div>