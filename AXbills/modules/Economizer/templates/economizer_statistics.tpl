<form method='POST'>
  <input type='hidden' name='index' value='$index'>
  <div class='card card-primary card-outline box-form form-horizontal'>
    <div class='card-body'>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{YEAR}_</label>
        <div class='col-md-6'>
          %YEARS_SELECT%
        </div>
        <div class='col-md-3'>
          <input class='btn btn-primary' type='submit' value='_{SHOW}_' name='SHOW'>
        </div>
      </div>
    </div>
  </div>
</form>

<div class='row'>
  <div class='col-md-12 col-sm-12'>
    <div class='card card-primary card-outline  form-horizontal'>
      <div class="card-header with-border">
        <h3 class="card-title">_{DIFFERENCE_PUBLIC_UTILITIES_FOR_PERIODS}_</h3>
        <div class="card-tools float-right">
          <button type="button" class="btn btn-box-tool" data-card-widget="collapse"><i class="fa fa-minus"></i></button>
        </div>
        <!-- /.box-tools -->
      </div>
      <div class='card-body'>
        %CHART_COUNTER%
      </div>
    </div>
  </div>

  <div class='col-md-12 col-sm-12'>
    <div class='card card-primary card-outline  form-horizontal'>
      <div class="card-header with-border">
        <h3 class="card-title">_{SPENT_MONEY_FOR_PUB_UTILITIES_FOR_PERIODS}_</h3>
        <div class="card-tools float-right">
          <button type="button" class="btn btn-box-tool" data-card-widget="collapse"><i class="fa fa-minus"></i></button>
        </div>
        <!-- /.box-tools -->
      </div>
      <div class='card-body'>
        %CHART_MONEY%
      </div>
    </div>
  </div>
  
  <div class='col-md-12 col-sm-12'>
    <div class='card card-primary card-outline  form-horizontal'>
      <div class="card-header with-border">
        <h3 class="card-title">_{AMOUNT_MONEY_SPENT}_</h3>
        <div class="card-tools float-right">
          <button type="button" class="btn btn-box-tool" data-card-widget="collapse"><i class="fa fa-minus"></i></button>
        </div>
        <!-- /.box-tools -->
      </div>
      <div class='card-body'>
        %CHART_MONEY_TOTAL%
      </div>
    </div>
  </div>
</div>