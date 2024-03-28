<form action='$SELF_URL' method='POST' class='form-horizontal' id='INTERNET_CLONE_FORM'>
  <input type='hidden' name='index' value="%INDEX%">
  <input type='hidden' name='TP_ID' value="%TP_ID%">
  <input type='hidden' name='ADD_CLONE_TP' value="1">

  <div class="form-group">
    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'>
        <h3 class="card-title">_{CLONE}_</h3>
      </div>
      <div class='card-body' id="div_body">
        <div class='form-group'>
          %INTERNET_TP_SELECT%
        </div>
        <input class='btn btn-primary' type='submit' value='_{CLONE}_'>
      </div>
    </div>
  </div>

</form>

<script>
  let hidden_input_id = document.createElement('input');
  let hidden_input_name = document.createElement('input');

  jQuery(hidden_input_id).attr({type: 'hidden', name: 'ID', value: jQuery('#ID').val()});
  jQuery(hidden_input_name).attr({type: 'hidden', name: 'NAME', value: jQuery('#NAME').val()});

  jQuery('#INTERNET_CLONE_FORM').append(hidden_input_id);
  jQuery('#INTERNET_CLONE_FORM').append(hidden_input_name);
</script>