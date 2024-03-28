<form name='form_setting' id='form_setting' method='post' class='form form-horizontal'>
    
    <input type='hidden' name='get_index' value='equipment_info'>
    <input type='hidden' name='TR_069' value='1'>
    <input type='hidden' name='onu_setting' value='1'>
    <input type='hidden' name='tr_069_id' value='%tr_069_id%'>
    <input type='hidden' name='header' value='2'>
    <input type='hidden' name='change' value='1'>
    <input type='hidden' name='info_pon_onu' value='%info_pon_onu%'>
    <input type='hidden' name='menu' value='%menu%'>
    <input type='hidden' name='sub_menu' value='%sub_menu%'>

    <div class='form-group'>
        <label class='control-label col-md-5' for='TYPE'>Connection type:</label>
        <div class='col-md-3 control-element'>
            %CONNECT_TYPE_SEL%
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='SERVICE'>Service:</label>
        <div class='col-md-3 control-element'>
            %SERVICE_LIST_SEL%
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='VLAN'>Vlan ID:</label>
        <div class='col-md-3 control-element'>
            <input type='text' name='vlan' value='%vlan%' class='form-control' ID='vlan' data-check-for-pattern='^\\d+\$' maxlength='4'/>
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='NAT'>NAT:</label>
        <div class='col-md-3 control-element'>
            %NAT_SEL%
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div id='pppoe_setting'>
        <div class='form-group'>
            <label class='control-label col-md-5' for='USER'>Username:</label>
            <div class='col-md-3 control-element'>
                <input type='text' name='ppp_user' value='%ppp_user%' class='form-control' ID='ppp_user' data-check-for-pattern='%USERNAMEREGEXP%'/>
            </div>
        </div>
        <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

        <div class='form-group'>
            <label class='control-label col-md-5' for='PASS'>Password:</label>
            <div class='col-md-3 control-element'>
                <input type='text' name='ppp_pass' value='%ppp_pass%' class='form-control' ID='ppp_pass'/>
            </div>
        </div>
        <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    </div>
    <div class='card-footer'>
        <input type='submit' name='change' value='_{CHANGE}_' ID='change' class='btn btn-primary'>
    </div>
</form>
<script>
    jQuery(document).ready(function(){
        pageInit('#form_setting');
        jQuery('#form_setting').submit(function(e) {
            if (!jQuery('#form_setting').find('.has-error').find('.form-control').attr( "id")) 
            {
                jQuery.ajax({
                    type: "POST",
                    url: "index.cgi",
                    data: jQuery('#form_setting').serialize(),
                    success: function(html)
                    {
                        jQuery('#ajax_content').html(html);
                    }
                });
            }
            e.preventDefault();
        });

        var pppoe_sel_div = jQuery('div#pppoe_setting');

        if (jQuery('select#connect_type').val() === 'pppoe') {
            pppoe_sel_div.show();
            jQuery('div#pppoe_setting #ppp_user').attr('name', 'ppp_user');
            jQuery('div#pppoe_setting #ppp_pass').attr('name', 'ppp_pass');
        }
        else {
            pppoe_sel_div.hide();
            jQuery('div#pppoe_setting #ppp_user').attr('name', 'ppp_user_');
            jQuery('div#pppoe_setting #ppp_pass').attr('name', 'ppp_pass_');
        }
        jQuery('select#connect_type').change(function () {
            if (jQuery('select#connect_type').val() === 'pppoe') {
                pppoe_sel_div.show();
                jQuery('div#pppoe_setting #ppp_user').attr('name', 'ppp_user');
                jQuery('div#pppoe_setting #ppp_pass').attr('name', 'ppp_pass');
            }
            else {
                pppoe_sel_div.hide();
                jQuery('div#pppoe_setting #ppp_user').attr('name', 'ppp_user_');
                jQuery('div#pppoe_setting #ppp_pass').attr('name', 'ppp_pass_');
            }
        });
    });
</script>
