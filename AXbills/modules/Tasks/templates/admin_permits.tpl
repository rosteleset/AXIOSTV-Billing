<form id='tasks_admins_form'>
  <input type='hidden' name='index' value='$index'>
  <input type='submit' value='_{SAVE}_' name='SAVE' class='btn btn-primary'>
</form>
<script type="text/javascript">
  jQuery(function() {
    jQuery( '#tasks_admins_form' ).submit(function() {
      jQuery( '#tasks_admins_ tbody tr' ).each(function() {
        var element = this;
        var aid = jQuery(element).find('input').attr('aid');
        var permits = [];
        permits.push(jQuery(element).find('.responsible').prop('checked')?1:0) ;
        permits.push(jQuery(element).find('.admin').prop('checked')?1:0) ;
        permits.push(jQuery(element).find('.sysadmin').prop('checked')?1:0) ;
        jQuery('<input />').attr('type', 'hidden')
          .attr('name', 'admin_' + aid)
          .attr('value', permits.join(','))
          .appendTo('#tasks_admins_form');
      });
    // event.preventDefault();
    return true;
    });
  });
</script>