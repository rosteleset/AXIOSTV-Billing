<div class='form-group'>
  <label for='STATE'>_{STATE}_</label>
  %STATE_SELECT%
</div>

<input type='submit' class='btn btn-danger'
       onclick="cancelEvent(event);showCommentsModal('_{CONFIRM}_', '', { event: 'DELETE_EVENTS', type : 'confirm' } )"
       name='del' value='_{DEL}_'/>
<button type='submit' name='change' value='1' class='btn btn-primary'>_{CHANGE}_</button>

<script>
  jQuery(function () {
    Events.once('DELETE_EVENTS', function () {
      var form = jQuery('form#' + '%FORM_ID%');
      form.append('<input type="hidden" name="del" value="1">');
      form.append('<input type="hidden" name="COMMENTS" value="%COMMENTS%">');
      form.submit();
    })
  });
</script>
