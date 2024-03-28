<div class='alert alert-danger' style='padding: 0' data-visible='%HAS_PAYMENT_MESSAGE%'>%PAYMENT_MESSAGE%</div>

<div class='card card-primary card-outline'>
  <div class='card-header with-border text-center'><h4 class='card-title'>_{DV}_</h4></div>
  <div class='card-body no-padding'>


      %PAYMENT_MESSAGE%
    <div class='card-body'>
      <h4 class='card-title text-center'>%NEXT_FEES_WARNING%</h4>
      <h4 class='card-title text-center'>%TP_CHANGE_WARNING%</h4>
    </div>

      %SERVICE_EXPIRE_DATE%

    <div class='panel-body'>
      <div class='table table-striped table-hover'>
        <div class='row'>
          <div class='col-md-3 text-1'>_{TARIF_PLAN}_:</div>
          <div class='col-md-9 text-2'>[%TP_ID%] <b>%TP_NAME%</b> <span class='extra'>%TP_CHANGE% </span> <br>%COMMENTS%
          </div>
        </div>

        %EXTRA_FIELDS%

        <div class='row'>
          <div class='col-md-3 text-1'>_{STATUS}_</div>
          <div class='col-md-9 text-2'>%STATUS_VALUE% %HOLDUP_BTN%</div>
        </div>
      </div>
    </div>
  </div>

<!--User cabinet footer will be broken if uncomment -->
</div>

