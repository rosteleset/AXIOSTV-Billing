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
        <label class='control-label col-md-5' for='SSID'>SSID:</label>
        <div class='col-md-3 control-element'>
            <input type='text' name='ssid' value='%ssid%' class='form-control' ID='ssid'/>
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='PASS'>Password:</label>
        <div class='col-md-3 control-element'>
            <input type='text' name='wlan_pass' value='%wlan_pass%' class='form-control' ID='wlan_pass' maxlength='20'/>
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='card-footer'>
        <input type='submit' name='change' value='_{CHANGE}_' ID='change' class='btn btn-primary'>
    </div>
</form>
<script>
    jQuery(document).ready(function(){
        pageInit('#form_setting');
        jQuery('#form_setting').submit(function(e) {
            jQuery.ajax({
                type: "POST",
                url: "index.cgi",
                data: jQuery('#form_setting').serialize(),
                success: function(html)
                {
                   jQuery('#ajax_content').html(html);
                }
            });
            e.preventDefault();
        });
    });
</script>
