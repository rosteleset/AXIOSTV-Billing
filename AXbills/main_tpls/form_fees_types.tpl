<div class='d-print-none'>
  <form action='$SELF_URL' name=user class='form form-horizontal'>
    <input type=hidden name=UID value='%UID%'>
    <input type=hidden name=index value='$index'>
    <input type=hidden name=subf value='$FORM{subf}'>
    <div class='card card-primary card-outline card-form'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{FEES}_ _{TYPES}_</h4>
      </div>
      <div class='card-body'>
        <div class="form-group row">
          <label class='col-md-3 control-label' for='ID'>ID:</label>
          <div class="col-md-9">
            <div class="input-group">
              <input type='text' class='form-control' ID='ID' name='ID' value='%ID%'>
            </div>
          </div>
        </div>

        <div class="form-group row">
          <label class='col-md-3 control-label' for='NAME'>_{NAME}_:</label>
          <div class="col-md-9">
            <div class="input-group">
              <input type='text' class='form-control' ID='NAME' name='NAME' value='%NAME%'>
            </div>
          </div>
        </div>

        <div class="form-group row">
          <label class='col-md-3 control-label' for='SUM'>_{SUM}_:</label>
          <div class="col-md-9">
            <div class="input-group">
              <input type='text' class='form-control' ID='SUM' name='SUM' value='%SUM%'>
            </div>
          </div>
        </div>

        <div class="form-group row">
          <label class='col-md-3 control-label' for='DEFAULT_DESCRIBE'>_{DESCRIBE}_ _{USER}_:</label>
          <div class="col-md-9">
            <div class="input-group">
              <input type=text class='form-control' ID='DEFAULT_DESCRIBE' name=DEFAULT_DESCRIBE
                     value='%DEFAULT_DESCRIBE%'>
            </div>
          </div>
        </div>

        <div class="form-group row">
          <label class='col-md-3 control-label' for='TAX'>_{TAX}_:</label>
          <div class="col-md-9">
            <div class="input-group">
              <input type=text class='form-control' name=TAX value='%TAX%' ID=TAX>
            </div>
          </div>
        </div>
      </div>
      <div class='card-footer'>
        <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
      </div>
    </div>
  </form>
</div>
