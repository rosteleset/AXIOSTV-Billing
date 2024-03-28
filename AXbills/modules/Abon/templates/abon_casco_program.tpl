<div class='col-md-4'>
  <div class='card'>
    <div class='card-body'>
      <div class='row'>
        <div class='col-8'>
          <h5 class='text-bold card-title'>%TITLE%</h5>
        </div>
        <div class='col-4'>
          <img class='img-fluid company-logo' src='%LOGO%'>
        </div>
      </div>
      <hr class='mr-1 mb-2'>

      <div class='mb-2'>
        %RATING%
      </div>

      <div class='card p-2 bg-light'>
        <div class='row'>
          <div class='col-8'>_{ABON_INSURANCE_LIMIT}_:</div>
          <div class='text-bold col-4'>%INSURANCE_SUM%</div>
        </div>
        <div class='row'>
          <div class='col-8'>_{FRANCHISE}_:</div>
          <div class='text-bold col-4'>%FRANCHISE%</div>
        </div>
        <div class='row'>
          <div class='col-8'>_{PRICE}_:</div>
          <div class='text-bold col-4'>%PRICE%</div>
        </div>
      </div>


      <div class='row'>
        <div class='col-6'>
<!--          <div class='panel-heading' role='tab' id='%PROGRAM_ID%_%PRICE%_accordion'>-->
<!--            <a class='btn btn-default' role='button' data-toggle='collapse' data-parent='#%PROGRAM_ID%_%PRICE%_accordion'-->
<!--               href='#collapse_%PROGRAM_ID%_%PRICE%'-->
<!--               aria-expanded='true' aria-controls='collapse_%PROGRAM_ID%_%PRICE%'>Детальніше</a>-->
<!--          </div>-->
        </div>
        <div class='col-6'>
          <a class='btn btn-primary float-right apply-program' data-id='%PROGRAM_ID%' data-franchise='%FRANCHISE%'
             data-price='%PRICE%'>_{ABON_CHOOSE}_</a>
        </div>
      </div>

      <div id='collapse_%PROGRAM_ID%_%PRICE%' data-parent='#%PROGRAM_ID%_%PRICE%_accordion'
           class='panel-collapse collapse out' role='tabpanel' aria-labelledby='accordion'>
        <div class='card-body'>
          %INFO%
        </div>
      </div>
    </div>
  </div>
</div>