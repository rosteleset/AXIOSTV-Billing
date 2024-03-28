<div class='row'>
  <div class='col-lg-4 col-md-6 col-sm-6  col-6'>
    <div class='info-box bg-green'>
      <span class='info-box-icon'><i class='fa fa-plus-square'></i></span>

      <div class='info-box-content'>
        <br>
        <span class='info-box-text'>_{ENABLE}_</span>
        <span class='info-box-number'>%ACTIVE_COUNT%</span>
      </div>

    </div>
  </div>

  <div class='col-lg-4 col-md-6 col-sm-6  col-6'>
    <div class='info-box bg-yellow'>
      <span class='info-box-icon'><i class='fa fa-minus-square'></i></span>

      <div class='info-box-content'>
        <br>
        <span class='info-box-text'>_{NOT}_ _{ENABLE}_</span>
        <span class='info-box-number'>%NOT_ACTIVE_COUNT%</span>
      </div>

    </div>
  </div>

</div>

%TABLE%

<div class='row'>
  <div class='col-lg-12 col-md-12 col-sm-12 col-6'>
    <div class='card card-primary card-outline collapsed-box'>
      <div class='card-header with-border'>
        <h4 class='card-title table-caption'>_{PURCHASES}_</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i></button>
        </div>
      </div>

      <div class='card-body'>
        %POPULAR_CHART%
      </div>

    </div>
  </div>
</div>


<div class='row'>
  <div class='col-lg-12 col-md-12 col-sm-12 col-6'>
    <div class='card card-primary card-outline collapsed-box'>
      <div class='card-header with-border'>
        <h4 class='card-title table-caption'>_{DOWNLOADS}_</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i></button>
        </div>
      </div>

      <div class='card-body'>
        %DOWNLOAD_CHART%
      </div>

    </div>
  </div>
</div>