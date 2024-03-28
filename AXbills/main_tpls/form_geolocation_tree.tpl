<form action=$SELF_URL METHOD=POST>
  <input type='hidden' name='index' value='%index%'>
  %HIDDEN_INPUTS%

  <div class='card card-primary card-outline' id='geolocation-card-container'>
    <div class='card-header with-border'><h4 class='card-title'>%TITLE%</h4></div>
    <div class='card-body' id='geolocation-card-body'>
      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          %GEOLOCATION_TREE%
        </div>
      </div>

      <div class='form-group custom-control custom-switch custom-switch-on-danger'>
        <input class='custom-control-input' type='checkbox' id='CLEAR' name='CLEAR' value='1'>
        <label for='CLEAR' class='custom-control-label'>_{CLEAR_GEO}_</label>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
    </div>
  </div>
</form>

<script>
  jQuery(document).ready(function () {
    jQuery('.tree_box').each(function () {
      if (jQuery(this).prop('checked')) {
        checkParent(jQuery(this));
        jQuery(this).parent().addClass('text-success');
        jQuery(this).closest('li').find('ul').find('input').each(function () {
          jQuery(this).prop('checked', true);
          jQuery(this).prop('disabled', true);
          jQuery(this).parent().addClass('text-success');
        })
      }
    });
    jQuery('.tree_box').change(function () {
      var a = jQuery(this).prop('checked');
      if (a) {
        jQuery(this).parent().addClass('text-success');
      } else {
        jQuery(this).parent().removeClass('text-success');
      }
      jQuery(this).closest('li').find('ul').find('input').each(function () {
        if (a) {
          jQuery(this).prop('checked', true);
          jQuery(this).prop('disabled', true);
          jQuery(this).parent().addClass('text-success');
        } else {
          jQuery(this).prop('checked', false);
          jQuery(this).prop('disabled', false);
          jQuery(this).parent().removeClass('text-success');
        }
      });
    });

    function checkParent(e) {
      let parent_id = e.data('parentId');
      if (!parent_id) return;
      let parent = jQuery('#' + parent_id);
      if (parent.prop('checked')) return;

      parent.parent().addClass('text-info');
      checkParent(parent);
    }
  });
</script>