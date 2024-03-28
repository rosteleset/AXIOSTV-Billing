<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name=index value=$index>
  <input type=hidden name='NAS_ID' value='%NAS_ID%'>
  <input type=hidden name='mrtg_cfg' value='1'>
  <div class='card card-primary card-outline box-form'>
    <!-- head -->
    <div class='card-header with-border'>
      <h4 class="card-title table-caption">Options</h4>
    </div>
    <!-- body -->
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>MRTG WorkDir</label>
        <div class="col-md-9">
          <input type="text" name="WORK_DIR" class="form-control" value="/usr/axbills/webreports/%NAME%" required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-sm-2 col-md-3'>SNMP Community</label>
        <div class='col-sm-10 col-md-9'>
          <input type="text" name="COMMUNITY" class="form-control" value="public" required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-sm-2 col-md-3'>MRTG Template</label>
        <div class='col-sm-10 col-md-9'>
          %SELECT%
        </div>
      </div>

    </div>
    <!-- footer -->
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='confirm' value='_{APPLY}_'>
    </div>

  </div>
</form>
