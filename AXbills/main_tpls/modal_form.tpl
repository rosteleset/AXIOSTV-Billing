<script type="text/javascript">
  jQuery(function () {
    var ButtonName  = '';
    var ButtonValue = '';
    jQuery(".btn").click(function(e) {
      ButtonName  = jQuery(this).attr('name');
      ButtonValue = jQuery(this).attr('value');
    });

    jQuery('form:not(.skip-pin)').on('submit', function(e) {
      var formId = jQuery(this).attr('id');
      if (typeof(formId) === 'undefined') {
        formId = 'undefid';
        jQuery(this).attr('id', formId);
      }
      if (jQuery('#modal_pin').val() == '') {
        e.preventDefault();
        jQuery('#modal_pin').attr('form', formId);
        jQuery('#modal_submit').attr('form', formId);
        jQuery('#modal_submit').attr('name', ButtonName);
        jQuery('#modal_submit').attr('value', ButtonValue);
        jQuery('.modal').modal('hide');
        jQuery('#pinmodal').modal('show');
        jQuery.post(jQuery(location).attr('href'), {send_pin: jQuery("input[name='PHONE']").val()});
        console.log(jQuery(location).attr('href'));
        console.log(jQuery("input[name='PHONE']").val());
      }
    });
  });
</script>

<div id='pinmodal' class='' role='dialog'>
  <div class='modal-dialog'>
    <div class='modal-content'>
      <div class='modal-header'>
        <h4 class='modal-title'>_{ENTER_PIN}_</h4>
        <button type='button' class='close' data-dismiss='modal'>&times;</button>
      </div>
      <div class='modal-body'>
        <div class='form-group'>
          <input type='text' name='PIN' id='modal_pin' class='form-control'>
        </div>
      </div>
      <div class='modal-footer'>
        <input type='submit' class='btn btn-primary' id='modal_submit'>
      </div>
    </div>
  </div>
</div>