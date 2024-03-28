<!--<div class='card card-info card-outline center-block'>-->
<!--  <div class='card-header with-border text-center'>-->
<!--    <h4 class='card-title'></h4>-->
<!--  </div>-->
<!--  <div class='card-body'>-->
<!--    <div class='table table-striped table-hover'>-->
<!--      <div class='form-group row'>-->
<!--        <div class='col-xs-12 col-sm-3 col-md-7 text-1'>_{NUMBER}_:</div>-->
<!--        <div class='col-xs-12 col-sm-9 col-md-5 text-2'><b>%NUMBER%</b></div>-->
<!--      </div>-->
<!--      <div class='form-group row'>-->
<!--        <div class='col-xs-12 col-sm-3 col-md-7 text-1'>_{TARIF_PLAN}_:</div>-->
<!--        <div class='col-xs-12 col-sm-9 col-md-5 text-2'>[%TP_ID%] <b>%TP_NAME%</b></div>-->
<!--      </div>-->
<!--      <div class='form-group row'>-->
<!--        <div class='col-xs-12 col-sm-3 col-md-7 text-1'>_{ALLOW_ANSWER}_:</div>-->
<!--        <div class='col-xs-12 col-sm-9 col-md-5 text-2'>%ALLOW_ANSWER%</div>-->
<!--      </div>-->
<!--      <div class='form-group row'>-->
<!--        <div class='col-xs-12 col-sm-3 col-md-7 text-1'>_{ALLOW_CALLS}_:</div>-->
<!--        <div class='col-xs-12 col-sm-9 col-md-5 text-2'>%ALLOW_CALLS%</div>-->
<!--      </div>-->
<!--      <div class='form-group row'>-->
<!--        <div class='col-xs-12 col-sm-3 col-md-7 text-1'>_{DISABLE}_:</div>-->
<!--        <div class='col-xs-12 col-sm-9 col-md-5 text-2'>%DISABLE%</div>-->
<!--      </div>-->
<!--    </div>-->
<!--  </div>-->
<!--</div>-->

<div class='card card-primary card-outline'>
  <div class='card-header with-border'>
    <h3 class='card-title'>VoIP _{INFO}_</h3>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body table-responsive p-0'>
    %PAYMENT_MESSAGE%
    %NEXT_FEES_WARNING%
    %TP_CHANGE_WARNING%
    <table class='table table-bordered table-sm'>
      <tr>
        <td>_{NUMBER}_</td>
        <td><b>%NUMBER%</b></td>
      </tr>
      <tr>
        <td><strong>_{TARIF_PLAN}_</strong></td>
        <td><strong>[%TP_ID%] <b>%TP_NAME%</b>%TP_CHANGE%</strong></td>
      </tr>
      <tr>
        <td>_{STATUS}_</td>
        <td>%DISABLE%</td>
      </tr>
      <tr>
        <td>_{ALLOW_ANSWER}_</td>
        <td>%ALLOW_ANSWER%</td>
      </tr>
      <tr>
        <td>_{ALLOW_CALLS}_</td>
        <td>%ALLOW_CALLS%</td>
      </tr>
    </table>
  </div>
</div>
