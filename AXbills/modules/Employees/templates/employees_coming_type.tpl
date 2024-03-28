<form action='$SELF_URL' METHOD=POST>
<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value='%ID%'>
<input type='hidden' id='DEFAULT_UNCLICK' name='DEFAULT_UNCLICK' value=''/>

<div class='card card-primary card-outline container-md'>
<div class='card-header with-border'>
  <h4 class='card-title table-caption'>_{ADD}_ _{TYPE}_</h4>
</div>
<div class='card-body'>
  <div class='form-group row'>
    <label class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
    <div class='col-md-8'>
      <input type='text' class='form-control' name='NAME' value='%NAME%' placeholder='_{TYPE_IN_COMING_TYPE}_'>
    </div>
  </div>
  <div class='form-group row'>
    <label class='col-md-4 col-form-label text-md-right' for='DEFAULT_COMING'>_{DEFAULT}_:</label>
    <div class='col-md-8'>
      <input type='checkbox' name='DEFAULT_COMING' id='DEFAULT_COMING' value='1' %CHECK_DEFAULT%>
    </div>
  </div>
  <div class='form-group row'>
    <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
    <div class='col-md-8'>
      <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
    </div>
  </div>
</div>
<div class='card-footer'>
  <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
</div>
</div>
</form>

<script>
    jQuery(function() {
        jQuery('#DEFAULT_COMING').change(function() {
            if(this.checked) {
                jQuery('#DEFAULT_UNCLICK').val('')
            } else {
                jQuery('#DEFAULT_UNCLICK').val('1')
            }
        });
    });
</script>