<form class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='visual' value='1'>
  <input type='hidden' name='sub' value='2'>
  <input type='hidden' name='NAS_ID' value='%NAS_ID%'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class="card-title">_{ADD}_ Vlan</h4>
    </div>
    <div class='card-body'>
      <div class="form-group">
        <div class="row">
          <div class="col-sm-12 col-md-4">
            <label class="control-label col-md-12">_{PORTS}_ _{FROM}_</label>
            <div class="input-group">
              <input type='number' class='form-control' name='ports_from' value = '1'>
            </div>
          </div>

          <div class="col-sm-12 col-md-4">
            <label class="control-label col-md-12">_{PORTS}_ _{TO}_</label>
            <div class="input-group">
              <input type='number' class='form-control' name='ports_to' value = '%PORTS%'>
            </div>
          </div>

          <div class="col-sm-12 col-md-4">
            <label class="control-label col-md-12">VLAN _{FROM}_</label>
            <div class="input-group">
              <input type='number' class='form-control' name='VLAN'>
            </div>
          </div>
        </div>
        <br/>
        <div class="form-group">
          <div class="row">
            <div class="col-sm-12 col-md-12">
              <input type='submit' class='btn btn-primary' name='vlans_add' value='_{CREATE}_'>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</form>
