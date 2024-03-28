<form action='$SELF_URL' METHOD=POST>
  <input type='hidden' name='index' value='$index'>
  <div class='box box-theme form-horizontal '>

    <div class='box-header with-border'>
      <h4 class="box-title table-caption">_{MOBILE_PAY_SET}_</h4>
      <div class="box-tools pull-right">
        <button type="button" class="btn btn-default btn-xs" data-widget="collapse">
          <i class="fa fa-minus"></i></button>
      </div>
    </div>

    <div class='box-body'>
      <div class="row align-items-center">
        <div class="col-md-6">
          <div class='form-group'>
            <label class='col-md-3 control-label'>_{MOBILE_PAY_ID_MERCHANT}_ </label>
            <div class='col-md-9'>
              <input type="text" name="MOBILE_PAY_ID_MERCHANT" class="form-control" placeholder="Id" value="%MOBILE_PAY_ID_MERCHANT%">
            </div>
          </div>
        </div>
        <div class="col-md-6">
          <div class='form-group' style='display: %HIDE_SOURCE_SELECT%'>
            <label class='col-md-3 control-label'>_{MOBILE_PAY_PASS_MERCHANT}_</label>
            <div class='col-md-9'>
              <input type="text" name="MOBILE_PAY_PASS_MERCHANT" class="form-control" placeholder="Password" value="%MOBILE_PAY_PASS_MERCHANT%">
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type='submit' class='btn btn-primary btn-block' value='_{SAVE}_' name='SAVE'>
    </div>

  </div>
</form>