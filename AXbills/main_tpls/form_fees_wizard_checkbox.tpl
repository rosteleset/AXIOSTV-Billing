<div class="checkbox">
  <label id='label'><input type="checkbox" id='chk_1'>_{WITHOUT_FEES}_</label>
</div>

<script>
  jQuery('form#form_wizard').on('submit', function(e) {
    cancelEvent(e);
    
    if ( jQuery("#chk_1").is(':checked') || jQuery("#SUM_0").val() > 0) {
      jQuery('form#form_wizard').off('submit');
      jQuery('form#form_wizard').submit();
    }
    else {
      jQuery("#label").css('color', 'red');
    }
  });
</script>
