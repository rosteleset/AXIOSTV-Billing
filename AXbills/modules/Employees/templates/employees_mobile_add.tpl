<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name=index value=$index>
  <input type='hidden' name=ID value='%ID%'>

  <div class='card card-primary card-outline container-md'>
    <!-- head -->
    <div class='card-header with-border'>_{EMPLOYEE}_</div>
    <!-- body -->
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{EMPLOYEE}_:</label>
        <div class='col-md-8'>
          %ADMINS%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{CELL_PHONE}_:</label>
        <div class='col-md-8'>
          %CELL_PHONE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DAY}_ _{MONTHES_A}_:</label>
        <div class='col-md-8'>
          %DAY_NUM%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{SUM}_:</label>
        <div class='col-md-8'>
          %MOB_SUM%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %MOB_STATUS%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MOB_COMMENT'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='2' name='MOB_COMMENT' id='MOB_COMMENT'>%MOB_COMMENT%</textarea>
        </div>
      </div>

    </div>
    <!-- footer -->
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>

  </div>

</form>
