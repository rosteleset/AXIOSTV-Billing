<input type='hidden' name='CASCO' value='1'>

<div class='form-group row'>
  <label class='col-md-4 col-form-label text-md-right required' for='CASCO_ADDRESS'>_{ADDRESS}_:</label>
  <div class='col-md-8'>
    <select id='CASCO_ADDRESS' name='CASCO_ADDRESS'></select>
  </div>
</div>

<script>
  jQuery(document).ready(function() {
    jQuery('#CASCO_ADDRESS').select2({
      width:'100%',
      minimumInputLength: 1,
      ajax: {
        url: '/api.cgi/abon/plugin/%SERVICE_ID%/info',
        dataType: 'json',
        delay: 250,
        data: function (params) {
          return {
            CITY: params.term
          };
        },
        processResults: function(data) {
          return {
            results: data
          };
        },
        cache: true
      }
    });

    jQuery('#ACCEPT_LICENSE').parent().parent().remove();
  });
</script>