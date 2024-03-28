<div class='col-md-4 col-xs-6 col-sm-6 mb-2'>
  <div class='card rounded item-card'>
    <div class='image-container'>
      <img class='w-100 item-image' src='%IMAGE_URL%' alt='%ARTICLE_NAME%'>
    </div>
    <div class='card-body text-center pb-0'>
      <h5 class='mb-3 article-name'>%ARTICLE_NAME%</h5>
      <p class='text-reset'>%ARTICLE_TYPE_NAME%</p>


      <div class='d-flex'>
        <div class='p-2'>
          <div class='d-flex justify-content-start align-items-stretch'>
            <input type='number' min='1' max='%MAX_COUNT%' style='width: 70px'
                   class='form-control count' value='1' required name='RACK_HEIGHT'/>
            <div class='align-self-center'><h6 class='h6 ml-1 mb-1'>%MEASURE_NAME%</h6></div>
          </div>
        </div>
        <div class='ml-auto p-2 align-self-center'>
          <h6 class='h6 mb-1 text-primary'>_{PRICE}_: %SELL_PRICE% %MONEY_UNIT_NAME%</h6>
        </div>
      </div>
      <div class='invalid-feedback'>
        _{ENTER_CORRECT_AMOUNT}_<br>
        _{YOU_CANNOT_BUY_MORE_THAN}_ %MAX_COUNT% %MEASURE_NAME%.
      </div>

    </div>
    <div class='card-footer'>
      %BUY_BTN%
    </div>
  </div>
</div>

