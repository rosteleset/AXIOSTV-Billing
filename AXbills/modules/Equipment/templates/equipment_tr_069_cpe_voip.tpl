<form name='form_setting' id='form_setting' method='post'>

    <input type='hidden' name='get_index' value='equipment_info'>
    <input type='hidden' name='TR_069' value='1'>
    <input type='hidden' name='onu_setting' value='1'>
    <input type='hidden' name='tr_069_id' value='%tr_069_id%'>
    <input type='hidden' name='header' value='2'>
    <input type='hidden' name='change' value='1'>
    <input type='hidden' name='info_pon_onu' value='%info_pon_onu%'>
    <input type='hidden' name='menu' value='%menu%'>
    <input type='hidden' name='sub_menu' value='%sub_menu%'>

    <div class='card-body'>
        <div class='form-group row'>
            <label class='col-sm-2 col-form-label' for='STATUS'>Status:</label>
            <div class='col-sm-3'>
                %STATUS_SEL%
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-form-label' for='SERVER'>Server:</label>
            <div class='col-sm-3'>
                %SERVER_FORM%
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-form-label' for='port'>Port:</label>
            <div class='col-sm-3'>
                <input type='text' name='port' value='%port%' class='form-control' ID='port' data-check-for-pattern='^\\d+\$' maxlength='10'/>
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-form-label' for='voip_user'>_{LOGIN}_:</label>
            <div class='col-sm-3'>
                <input type='text' name='voip_user' value='%voip_user%' class='form-control' ID='voip_user'/>
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-form-label' for='voip_pass'>_{PASSWORD}_:</label>
            <div class='col-sm-3'>
                <input type='text' name='voip_pass' value='%voip_pass%' class='form-control' ID='voip_pass'/>
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-form-label' for='voip_number'>_{NUMBER}_:</label>
            <div class='col-sm-3'>
                <input type='text' name='voip_number' value='%voip_number%' class='form-control' ID='voip_number' data-check-for-pattern='^\\d+\$'/>
            </div>
        </div>

        <div class='form-group row'>
            <input type='submit' name='change' value='_{CHANGE}_' ID='change' class='btn btn-primary'>
        </div>
    </div>
</form>

<script>
    jQuery(document).ready(function(){
        pageInit('#form_setting');
        jQuery('#form_setting').submit(function(e) {
            if (!jQuery('#form_setting').find('.has-error').find('.form-control').attr('id'))
            {
                jQuery.ajax({
                    type: 'POST',
                    url: 'index.cgi',
                    data: jQuery('#form_setting').serialize(),
                    success: function(html)
                    {
                        jQuery('#ajax_content').html(html);
                    }
                });
            }
            e.preventDefault();
        });
    });
</script>
