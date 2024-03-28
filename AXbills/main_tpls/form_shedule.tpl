<form action='$SELF_URL' class='form-horizontal' method='post'>
<input type='hidden' name='index' value='$index'>

<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{SHEDULE}_</h4></div>
    <div class='card-body'>
      <div class="form-group">
        <div class="row">
          <div class="col-sm-12 col-md-4">
            <label for='SEL_D' class='control-label col-md-10'>_{DAY}_</label>
            <div class="input-group">
              %SEL_D%
            </div>
          </div>

          <div class="col-sm-12 col-md-4">
            <label for='SEL_M' class='control-label col-md-10'>_{MONTH}_</label>
            <div class="input-group">
              %SEL_M%
            </div>
          </div>

          <div class="col-sm-12 col-md-4">
            <label for='SEL_Y' class='control-label col-md-10'>_{YEAR}_</label>
            <div class="input-group">
              %SEL_Y%
            </div>
          </div>
        </div>
      </div>

      <div class="form-group">
        <div class="row">
          <div class="col-sm-12 col-md-6">
            <label for='COUNTS' class='control-label col-md-10'>_{COUNT}_</label>
            <div class="input-group">
              <input class='form-control' id='COUNTS' placeholder='%COUNTS%' name='COUNTS' value='%COUNTS%'>
            </div>
          </div>

          <div class="col-sm-12 col-md-6">
            <label for='SEL_TYPE' class='control-label col-md-10'>_{TYPE}_:</label>
            <div class="input-group">
              %SEL_TYPE%
            </div>
          </div>
        </div>
      </div>

      <div class="form-group">
        <div class="row">
          <div class="col-sm-12 col-md-6">
            <label class='col-md-10'>_{ACTION}_</label>
            <div class="input-grop">
              <textarea cols='30' rows='4' name='ACTION' class='form-control'>%ACTION%</textarea>
            </div>
          </div>

          <div class="col-sm-12 col-md-6">
            <label class='col-md-10'>_{COMMENTS}_</label>
            <div class="input-grop">
              <textarea cols='30' rows='4' name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name=add value='_{ADD}_'>
    </div>
</div>
</form>