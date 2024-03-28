<form action='$SELF_URL' method='post' name='add_message' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='AID' value='%AID%'/>
  <div class='container-fluid'>
    <div class='row'>
      <div class='col-md-12'>
        <div class='card card-primary card-outline box-big-form'>
          <div class='card-header with-border'><h4 class='card-title'>_{DISPATCH}_</h4>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label class='col-form-label text-md-right col-md-3' for='PLAN_DATE'>_{EXECUTION}_:</label>
              <div class='col-md-9'>
                %PLAN_DATE%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-md-3' for='STATUS'>_{STATUS}_:</label>
              <div class='col-md-9'>
                %STATE_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-md-3' for='CREATED_BY'>_{DISPATCH_CREATE}_:</label>
              <div class='col-md-9'>
                %CREATED_BY_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-md-3' for='RESPOSIBLE'>_{HEAD}_:</label>
              <div class='col-md-9'>
                %RESPOSIBLE_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-md-3' for='NAME'>_{DISPACTH_CATEGORY}_:</label>
              <div class='col-md-9'>
                %CATEGORY_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-md-3' for='START_DATE'>_{TIME_START_WORK}_:</label>
              <div class='col-md-9'>
                %START_DATE%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-md-3' for='END_DATE'>_{TIME_END_WORK}_:</label>
              <div class='col-md-9'>
                %END_DATE%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-md-3' for='ACTUAL_END_DATE'>_{ACTUAL_TIME_END}_:</label>
              <div class='col-md-9' disabled>
                %ACTUAL_END_DATE%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-sm-3' for='COMMENTS'>_{COMMENTS}_:</label>
              <div class='col-md-9'>
                <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='row'>
      <div class='col-md-12'>
        <div class='card card-primary card-outline collapsed-card'>
          <div class='card-header with-border'><h4 class='card-title'>_{BRIGADE}_</h4>
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
                  %AIDS%
                </ul>
              </div>
              <div class='col-md-6'>
                <ul class='list-group'>
                  %AIDS2%
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='card-footer'>
    <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
  </div>
</form>

<script>
  initDatepickers();

  jQuery('.list-checkbox').each(function () {
    if (jQuery(this).is(":checked")) {
      jQuery(this).parent().addClass('list-group-item-success');
    }
  });

  jQuery('.list-checkbox').change(function () {
    if (jQuery(this).is(':checked')) {
      jQuery(this).parent().addClass('list-group-item-success');
    } else {
      jQuery(this).parent().removeClass('list-group-item-success');
    }
  });
</script>
