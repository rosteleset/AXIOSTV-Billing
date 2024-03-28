<form action='$SELF_URL' method='POST'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ARTICLE_ID' value='%ARTICLE_ID%'>
  <input type='hidden' name='MAIN_ARTICLE_ID' value='%SIA_ID%'>
  <input type='hidden' name='INCOMING_ARTICLE_ID' value='%STORAGE_INCOMING_ID%'>
  <input type='hidden' name='SELL_PRICE' value='%SELL_PRICE%'>
  <input type='hidden' name='RENT_PRICE' value='%RENT_PRICE%'>
  <input type='hidden' name='IN_INSTALLMENTS_PRICE' value='%IN_INSTALLMENTS_PRICE%'>
  <input type='hidden' name='SUM' value='%SUM%'>
  <input type='hidden' name='SUM_TOTAL' value='%TOTAL_SUM%'>
  <input type='hidden' name='TOTAL_COUNT' value='%TOTAL%'>

  %DIVIDE_TABLE%

  <input type='submit' id='DIVIDE_BUTTON' name='divide_all' value='_{DIVIDE}_' class='btn btn-primary'>
</form>



<script>
  var timeout = null;

  function doDelayedSearch(val, element) {
    if (timeout) {
      clearTimeout(timeout);
    }
    document.getElementById('DIVIDE_BUTTON').disabled = true;
    timeout = setTimeout(function() {
      doSearch(val, element); //this is your existing function
    }, 500);
  }

  function doSearch(val, element) {
    if(!val){
      jQuery(element).parent().parent().removeClass('has-success').addClass('has-error');
      document.getElementById('DIVIDE_BUTTON').disabled = false;
      return 1;
    }

    if (checkInputsDuplicates(val)) {
      changeInputStatus(element, false);
      return 1;
    }

    jQuery.post('$SELF_URL', 'header=2&qindex=' + '%CHECK_SN_INDEX%' + '&sn_check=' + val, function (data) {
      changeInputStatus(element, data === 'success');
    });
  }

  function checkInputsDuplicates(val) {
    let coincidences = 0;

    jQuery('.sn_check_class').each(function() {
      if (jQuery(this).val() === val) coincidences++;
    });

    return coincidences > 1;
  }

  function changeInputStatus(element, success = true) {
    document.getElementById('DIVIDE_BUTTON').disabled = false;
    if (success) {
      jQuery(element).parent().removeClass('has-error').addClass('has-success');
      jQuery(element).css('border', '3px solid green');
      element.setCustomValidity('');
      return;
    }
    jQuery(element).parent().removeClass('has-success').addClass('has-error');
    jQuery(element).css('border', '3px solid red');
    element.setCustomValidity('_{SERIAL_NUMBER_IS_ALREADY_IN_USE}_');
  }

  jQuery('.sn_check_class').on('input', function(event){
    var element = event.target;
    var value = jQuery(element).val();
    doDelayedSearch(value, element);
  });
</script>