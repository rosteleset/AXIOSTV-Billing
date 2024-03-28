<form METHOD=POST action='%SELF_URL%'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%chg%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>
        _{ADD_ACCIDENT}_
      </h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' name='NAME' id='NAME' value='%NAME%' placeholder='_{NAME}_' class='form-control' required>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='DESCR'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea name='DESCR' id='DESCR' placeholder='_{DESCRIBE}_' class='form-control' required>%DESCR%</textarea>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          %SELECT_PRIORITY%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %SELECT_STATUS%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{ADMIN}_:</label>
        <div class='col-md-8'>
          %ADMIN_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DATE}_:</label>
        <div class='col-md-8'>
          %DATE%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{WORK_END_DATE}_:</label>
        <div class='col-md-8'>
          %DATEPICKER_END%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{WORK_REALY_DATE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' class='form-control-static' data-input-enables='REALY_TIME'/>
              </span>
            </div>
            %DATEPICKER_REAL%
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>Населенные пункты:</label>
        <div class='col-md-8'>
          %GEOLOCATION_TREE%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary float-right' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>

<script>
  var _EMPTY_FIELD = '_{WITHOUT_CITY}_';

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