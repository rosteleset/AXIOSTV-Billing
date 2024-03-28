<form class='col-md-4 mb-3' action=%SELF_URL% method='POST'>
  <input class='form-control' type='hidden' name='index' value='%index%'/>
  <div class='card card-primary abon-card'>
    <div class='card-header text-center border-0'>
      <h3 class='card-title' style='float: unset'>%TP_NAME%</h3>
    </div>
    <div class='card-body'>
      <div class='tile-body'>
        <div>
          <div class='abon-card-img-container d-flex justify-content-center align-items-center'>
            <img src='%SERVICE_IMG%' class='abon-card-img'>
          </div>
          <p class='m-0'>%DESCRIPTION%</p>
          <div class='text-center mt-3'><p>%PERSONAL_DESCRIPTION%</p></div>
          %ADDON%
        </div>
        <div class='button-wrapper justify-content-between row m-0' style='gap: 8px'>
          <div class='row flex-nowrap px-1'>
            <div>
              <p class='sum'>%PRICE%</p>
            </div>
            <div class='pl-1 units'>
              %UNIT%
              <br>
              /%PERIOD%
            </div>
          </div>
          <div class='ml-auto'>
            %BUTTON%
          </div>
        </div>
      </div>
    </div>
  </div>
</form>
