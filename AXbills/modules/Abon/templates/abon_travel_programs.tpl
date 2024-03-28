<input type='hidden' name='INSURANCE_OBJECTS_AGE' value='%INSURANCE_OBJECTS_AGE%'>
<input type='hidden' name='BEGINNING_DATE' value='%BEGINNING_DATE%'>
<input type='hidden' name='ENDING_DATE' value='%ENDING_DATE%'>
<input type='hidden' name='TRAVEL_AREA' value='%TRAVEL_AREA%'>
<input type='hidden' name='PURPOSE' value='%PURPOSE%'>
<input type='hidden' name='MULTI_VISA_DAYS' value='%MULTI_VISA_DAYS%'>
<input type='hidden' name='TRIPS_COUNT' value='%TRIPS_COUNT%'>
<input type='hidden' name='INSURANCE_SUM' value='%INSURANCE_SUM%'>
<input type='hidden' id='PRICE' name='PRICE'>
<input type='hidden' id='PACKAGE_ID' name='PACKAGE_ID'>
<input type='hidden' id='COMPANY_ID' name='COMPANY_ID'>

%OFFERS_TABLE%

<script>
  jQuery(document).ready(function () {
    jQuery('#ACCEPT_LICENSE').parent().parent().remove();
    jQuery(`[name='ACCEPT']`).parent().remove();

    jQuery('.apply-program').on('click', function() {
      jQuery('.apply-program').addClass('disabled');

      let program = jQuery(this);
      jQuery('#PACKAGE_ID').val(program.data('id'));
      jQuery('#PRICE').val(program.data('price'));
      jQuery('#COMPANY_ID').val(program.data('company'));

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