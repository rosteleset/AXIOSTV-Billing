<input type='hidden' name='CITY_ID' value='%CITY_ID%'>
<input type='hidden' name='ZONE_ID' value='%ZONE_ID%'>
<input type='hidden' id='PROGRAM_ID' name='PROGRAM_ID'>
<input type='hidden' id='PRICE' name='PRICE'>
<input type='hidden' id='FRANCHISE' name='FRANCHISE'>

%PROGRAMS_TABLE%

<script>
  jQuery(document).ready(function () {
    jQuery('#ACCEPT_LICENSE').parent().parent().remove();
    jQuery(`[name='ACCEPT']`).parent().remove();

    jQuery('.apply-program').on('click', function() {
      jQuery('.apply-program').addClass('disabled');

      let program = jQuery(this);
      jQuery('#PROGRAM_ID').val(program.data('id'));
      jQuery('#FRANCHISE').val(program.data('franchise'));
      jQuery('#PRICE').val(program.data('price'));

      jQuery('#license_form').submit();
    })
  });
</script>

<style>
	.company-logo {
		max-height: 20px !important;
		float: right;
	}
</style>