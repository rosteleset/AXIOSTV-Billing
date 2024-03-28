<input type='hidden' name='CAR_TYPE' value='%CAR_TYPE%'>
<input type='hidden' name='ZONE_ID' value='%ZONE_ID%'>
<input type='hidden' name='PERIOD_ID' value='%PERIOD_ID%'>
<input type='hidden' id='PRICE' name='PRICE'>
<input type='hidden' id='COMPANY_ID' name='COMPANY_ID'>
<input type='hidden' name='CALCULATION_ID' value='%CALCULATION_ID%'>

%OFFERS_TABLE%

<script>
  jQuery(document).ready(function () {
    jQuery('#ACCEPT_LICENSE').parent().parent().remove();
    jQuery(`[name='ACCEPT']`).parent().remove();

    jQuery('.apply-program').on('click', function() {
      jQuery('.apply-program').addClass('disabled');

      jQuery('#PRICE').val(jQuery(this).data('price'));
      jQuery('#COMPANY_ID').val(jQuery(this).data('company'));

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