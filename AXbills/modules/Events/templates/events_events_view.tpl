<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{EVENT}_ №%ID%</h4></div>
  <div class='card-body row'>
    <div class='col-md-3'>
      <div class='form-group row'>
        <label class='control-label col-md-4'>_{MODULE}_: </label>
        <p class='control-label'>%MODULE%</p>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{GROUP}_: </label>
        <p class='control-label'>
          <a title='%GROUP_MODULES%' href='?get_index=events_group_main&full=1&chg=%GROUP_ID%'>%GROUP_NAME%</a>
        </p>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{STATE}_: </label>
        <p class='control-label'>%STATE_NAME_TRANSLATED%</p>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{PRIORITY}_: </label>
        <p class='control-label'>%PRIORITY_NAME_TRANSLATED%</p>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{CREATED}_: </label>
        <p class='control-label'><strong>%CREATED%</strong>
        <br>
        <span class='moment-insert' data-value='%CREATED%'></span></p>
      </div>

      <div class='form-group row' data-visible='%EXTRA%'>
        <label class='control-label col-md-4'>URL: </label>
        <p class='control-label'><a href='%EXTRA%' target='_blank'>%EXTRA%</a></p>
      </div>
    </div>

    <div class='col-md-9'>
      <div class='form-group'>
        <label>_{COMMENTS}_: </label>
        <textarea class='form-control' rows='6'>%COMMENTS%</textarea>
      </div>
    </div>

    <!--
    <div class='form-group'>
      <label for='PRIVACY'>_{ACCESS}_: </label>
        <p class='form-control'>%PRIVACY_NAME_TRANSLATED%</p>
    </div>
    -->

  </div>
</div>

