<form id='paysys-terminals-add' METHOD='POST' class='form form-horizontal'>

  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ACTION' value='%ACTION%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TERMINALS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %TERMINAL_TYPE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS%
        </div>
      </div>

      <hr>
      %ADRESS_FORM%
      <hr>

      <div class='row'>
        <div class='col-md-12'>
          <div class='card card-primary card-outline collapsed-card'>
            <div class='card-header with-border'><h4 class='card-title'>_{WORK_DAYS}_</h4>
              <div class='card-tools float-right'>
                <button type='button' class='btn btn-tool' data-card-widget='collapse'><i
                          class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='card-body'>
              <div class='row'>
                <div class='col-md-6'>
                  <ul class='list-group'>
                    %WEEK_DAYS1%
                  </ul>
                </div>
                <div class='col-md-6'>
                  <ul class='list-group'>
                    %WEEK_DAYS2%
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='START_WORK'>_{START}_:</label>
        <div class='col-md-8'>
          %START_WORK%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='END_WORK'>_{END}_:</label>
        <div class='col-md-8'>
          %END_WORK%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='COMMENT'>%COMMENT%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='DESCRIPTION'>%DESCRIPTION%</textarea>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <button class='btn btn-primary' type='submit'>%BTN%</button>
    </div>

  </div>

</form>

<script>
  initDatepickers();

  jQuery('.list-checkbox').each(function () {
    console.log(jQuery(this));
    if (jQuery(this).is(':checked')) {
      if (jQuery(this).val() == 6 || jQuery(this).val() == 7) {
        jQuery(this).parent().addClass('list-group-item-danger');
      } else {
        jQuery(this).parent().addClass('list-group-item-success');
      }
    }
  });

  jQuery('.list-checkbox').change(function () {
    console.log(jQuery(this).val());
    if (jQuery(this).is(':checked')) {
      if (jQuery(this).val() == 6 || jQuery(this).val() == 7) {
        jQuery(this).parent().addClass('list-group-item-danger');
      } else {
        jQuery(this).parent().addClass('list-group-item-success');
      }
    } else {
      if (jQuery(this).val() == 6 || jQuery(this).val() == 7) {
        jQuery(this).parent().removeClass('list-group-item-danger');
      } else {
        jQuery(this).parent().removeClass('list-group-item-success');
      }
    }
  });
</script>
