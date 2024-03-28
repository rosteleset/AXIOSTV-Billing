<form class='form-horizontal' action='$SELF_URL' method='post' role='form'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='TP_ID' value='%TP_ID%'>
  <input type=hidden name='TI_ID' value='%TI_ID%'>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{INTERVALS}_</h4>
    </div>

    <div class='card-body'>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 col-form-label" for='DAYS'>_{DAY}_</label>
        <div class="col-sm-8 col-md-8">
          %SEL_DAYS%
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 col-form-label" for='TI_BEGIN'>_{BEGIN}_</label>
        <div class="col-sm-8 col-md-8">
          <input id='TI_BEGIN' name='TI_BEGIN' value='%TI_BEGIN%' placeholder='%TI_BEGIN%' class='form-control' type='text'>
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 col-form-label" for='TI_END'>_{END}_</label>
        <div class="col-sm-8 col-md-8">
          <input id='TI_END' name='TI_END' value='%TI_END%' placeholder='%TI_END%' class='form-control' type='text'>
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 col-form-label" for='PHONE'>_{HOUR_TARIF}_ (0.00)</label>
        <div class="col-sm-8 col-md-8">
          <input id='TI_TARIF' name='TI_TARIF' value='%TI_TARIF%' placeholder='%TI_TARIF%' class='form-control' type='text'>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
