<form action=$SELF_URL name=well_add_form id=WELL_ADD_FORM class='form form-horizontal'>

  <input type=hidden name=COORDX value=%COORDX%>
  <input type=hidden name=COORDY value=%COORDY%>

  <input type='hidden' name='LAYER_ID' value='4'/>
  <input type='hidden' name='get_index' value='maps_edit'/>
  <input type='hidden' name='header' value='2'/>
  <input type='hidden' name='add' value='1'/>
  <input type='hidden' name='AJAX' value='1'/>

  <div class='card box-primary'>
    <div class='card-header'>
      <h4>_{ADD_WELL}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group'>
        <label class='control-label col-md-3 required' for='wellName'>_{NAME}_:</label>

        <div class='col-md-9'>
          <input class='form-control' type=text name=NAME id='wellName' maxlength="33" required="required">
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3' for='wellDescribe'>_{DESCRIBE}_:</label>

        <div class='col-md-9'>
          <textarea class='form-control' name=COMMENT id='wellDescribe' cols=30 rows=5></textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type=submit name=add_well value=_{ADD}_ class='btn btn-primary'>
    </div>
  </div>
</form>

<script>
  // Sending form as AJAX request, to prevent tab reloading
  var form_id = 'WELL_ADD_FORM';
  var form = jQuery('form#' + form_id);

  form.on('submit', function (e) {
    e.preventDefault();

    var formData = form.serialize();

    form.find('input[type="submit"]').addClass('disabled');

    jQuery.post(form.attr('action'), formData, function (data) {
      aModal.updateBody(data);
    });
  });
</script>

