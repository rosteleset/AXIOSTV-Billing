<div class='card card-primary card-outline card-form'>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-form-label col-md-4' for='NAS_ID'>_{SELECT_OLT}_:</label>
      <div class='col-md-8'>
        %OLT_SEL%
      </div>
    </div>
  </div>
</div>

<script>
  jQuery(document).ready(function(){
    jQuery('#NAS_ID').change(function(){
      var nas_id = jQuery('#NAS_ID').val();
      var link = 'index.cgi?index=%INDEX%&visual=4&NAS_ID=' + nas_id;
      window.location.assign(link);
    });
  });
</script>
