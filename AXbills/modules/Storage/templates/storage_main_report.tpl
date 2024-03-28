<div class='row'>
  <!--IN STORAGE-->
  <div class='col-md-4 col-sm-6 col-xs-12'>
    <div class='small-box bg-primary'>
      <div class='inner'>
        <h3>%IN_STORAGE% / %IN_STORAGE_SUM%</h3>

        <p>_{IN_STORAGE}_</p>
      </div>
      <div class='icon'>
        <i class='fas fa-shopping-bag'></i>
      </div>
      <a href='%SHOW_IN_STORAGE%' class='small-box-footer'>_{SHOW}_<i class='fa fa-arrow-circle-right'></i></a>
    </div>
  </div>

  <!--INSTALLED-->
  <div class='col-md-4 col-sm-6 col-xs-12'>
    <div class='small-box bg-success'>
      <div class='inner'>
        <h3>%INSTALATION% / %INSTALATION_SUM%</h3>

        <p>_{INSTALLED}_</p>
      </div>
      <div class='icon'>
        <i class='fas fa-shopping-bag'></i>
      </div>
      <a href='%SHOW_INSTALLED%' class='small-box-footer'>_{SHOW}_<i class='fa fa-arrow-circle-right'></i></a>
    </div>
  </div>

  <!--INNER USE-->
  <div class='col-md-4 col-sm-6 col-xs-12'>
    <div class='small-box bg-orange'>
      <div class='inner'>
        <h3>%INNER_USE% / %INNER_USE_SUM%</h3>

        <p>_{INNER_USE}_</p>
      </div>
      <div class='icon'>
        <i class='fas fa-shopping-bag'></i>
      </div>
      <a href='%SHOW_INNER_USE%' class='small-box-footer'>_{SHOW}_<i class='fa fa-arrow-circle-right'></i></a>
    </div>
  </div>
</div>

<div class='row'>
  <!--DISCARDED-->
  <div class='col-md-4 col-sm-6 col-xs-12'>
    <div class='small-box bg-danger'>
      <div class='inner'>
        <h3>%DISCARDED% / %DISCARDED_SUM%</h3>

        <p>_{DISCARDED}_</p>
      </div>
      <div class='icon'>
        <i class='fas fa-shopping-bag'></i>
      </div>
      <a href='%SHOW_DISCARDED%' class='small-box-footer'>_{SHOW}_ <i class='fa fa-arrow-circle-right'></i></a>
    </div>
  </div>

  <!--RESERVED-->
  <div class='col-md-4 col-sm-6 col-xs-12'>
    <div class='small-box bg-black'>
      <div class='inner'>
        <h3>%RESERVE% / %RESERVE_SUM%</h3>

        <p>_{RESERVED}_</p>
      </div>
      <div class='icon'>
        <i class='fas fa-shopping-bag'></i>
      </div>
      <a href='%SHOW_RESERVED%' class='small-box-footer'>_{SHOW}_<i class='fa fa-arrow-circle-right'></i></a>
    </div>
  </div>

  <!-- fix for small devices only -->
  <div class='clearfix visible-sm-block'></div>

  <!--ACOUNTABILITY-->
  <div class='col-md-4 col-sm-6 col-xs-12'>
    <div class='small-box bg-aqua'>
      <div class='inner'>
        <h3>%ACCOUNTABILITY% / %ACCOUNTABILITY_SUM%</h3>

        <p>_{ACCOUNTABILITY}_</p>
      </div>
      <div class='icon'>
        <i class='fas fa-shopping-bag'></i>
      </div>
      <a href='%SHOW_ACCOUNTABILITY%' class='small-box-footer'>_{SHOW}_<i class='fa fa-arrow-circle-right'></i></a>
    </div>
  </div>

</div>

<hr>

<div class='row'>
  <div class='col-md-4'>
    <div class='card'>
      <div class='card-header'>_{STATS}_</div>
      <div class='card-body'>
        %CHARTS%
      </div>
    </div>
  </div>
  <div class='col-md-8'>
    %HISTORY%
  </div>
</div>