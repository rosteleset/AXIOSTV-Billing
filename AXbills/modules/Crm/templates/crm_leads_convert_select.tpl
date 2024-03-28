<form id='LEAD_CONVERT' action='$SELF_URL' method='POST' class='form-horizontal'>

  <input type='hidden' name='index' value='$index'>
  <input type='hidden' id='FROM_LEAD_ID' name='FROM_LEAD_ID' value='%FROM_LEAD_ID%'>
  <input type='hidden' name='TO_LEAD_ID' value='%TO_LEAD_ID%'>

  <div class='card-body'>
    <div class='form-group row'>
      <div class='col-md-3 control-label'>_{CHOOSE}_ _{OF_LEAD}_:</div>
      <div class='col-md-9'>%TO_LEAD_SELECT%</div>
    </div>
  </div>

</form>

<script type='text/javascript'>
jQuery(function() {
  var lead_selection_form = jQuery('form#LEAD_CONVERT');
  var lead_id_select      = jQuery('select#TO_LEAD_ID');

  if (!lead_id_select.length) return true;

  var current_lead_id     = jQuery('input#FROM_LEAD_ID').val();

  lead_selection_form.on('submit', function(e){
    cancelEvent(e);
    var lead_id = lead_id_select.val();
    var load_url = '/admin/index.cgi?get_index=crm_lead_convert&header=2' 
        + '&FROM_LEAD_ID=' + current_lead_id
        + '&TO_LEAD_ID=' + lead_id;

    jQuery.get(load_url, function(data){
      aModal.updateBody(data, 300);
      loadToModal(load_url);
    });

  });
});

</script>