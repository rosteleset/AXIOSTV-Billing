<form action='$SELF_URL' METHOD=POST>
  <input type='hidden' name='index' value='$index'>

  <div class='card card-primary card-outline form-horizontal '>
    <div class='card-header with-border'>
      <h4 class="card-title table-caption">_{FILTERS}_</h4>
      <div class="card-tools float-right">
        <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse">
          <i class="fa fa-minus"></i></button>
      </div>
    </div>

    <div class='card-body'>
      <div class="row align-items-center">

        <div class="col-sm-12 col-md-6">
          <div class='form-group' >
            <label class='col-md-3 control-label'>_{ADMIN}_</label>
            <div class='col-md-9'>
              %AID_SELECT%
            </div>
          </div>
        </div>

      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary btn-block' value='_{SHOW}_' name='show'>
    </div>
  </div>
</form>