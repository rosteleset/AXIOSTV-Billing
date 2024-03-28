<input type='hidden' name='OSAGO_PROGRAM_SELECTED' value='1'>
<input type='hidden' name='CAR_TYPE' value='%CAR_TYPE%'>
<input type='hidden' name='REG_ID' value='%REG_ID%'>
<input type='hidden' name='REG_NUMBER' value='%REG_NUMBER%'>
<input type='hidden' name='PRIVILEGE_TYPE' value='%PRIVILEGE_TYPE%'>
<input type='hidden' name='TAXI' value='%TAXI%'>
<input type='hidden' name='OTK_NEXT_DATE' value='%OTK_NEXT_DATE%'>
<input type='hidden' name='NOT_PASS_OTK' value='%NOT_PASS_OTK%'>
<input type='hidden' name='CLIENT_TYPE' value='%CLIENT_TYPE%'>
<input type='hidden' id='PROGRAM_ID' name='PROGRAM_ID'>
<input type='hidden' id='COSTS' name='COSTS'>

%PROGRAMS_TABLE%

<script>
  jQuery(document).ready(function () {
    jQuery('#ACCEPT_LICENSE').parent().parent().remove();
    jQuery(`[name='ACCEPT']`).parent().remove();

    jQuery('.apply-program').on('click', function() {
      jQuery('.apply-program').addClass('disabled');

      let program = jQuery(this);
      jQuery('#PROGRAM_ID').val(program.data('id'));
      jQuery('#COSTS').val(program.data('price'));

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