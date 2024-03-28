<input type='hidden' name='ID' value='$FORM{COMPANY_ID}'/>

<div class='form-group row'>
  <div class='col-sm col-12 form-group'>
    <div class='info-box h-100'>
      <span class='info-box-icon bg-success'>
        <i class='far fa-money-bill-alt'></i>
      </span>
      <div class='info-box-content pr-0'>
        <div class='row'>
          <h3 class='col-md-12'>
            <span class='info-box-number %DEPOSIT_MARK%' title='%DEPOSIT%'>%SHOW_DEPOSIT% %BUTTON_SHOW_LAST%</span>
          </h3>
        </div>
        <span class='info-box-text row'>
          <div class='btn-group col-md-12'>
            %PAYMENTS_BUTTON% %FEES_BUTTON% %PRINT_BUTTON%
          </div>
        </span>
      </div>
    </div>
  </div>

  <div id='CUSTOM_DISABLE_FORM' class='col-sm col-12 form-group h-0-18'>
    <div class='info-box h-100'>
      <div class='info-box-content'>
        <span class='info-box-text text-center'></span>
        <div class='info-box-content'>
          <div class='text-center'>
            <div class='custom-control custom-switch custom-switch-on-danger custom-switch-off-success'>
              %FORM_DISABLE%
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
  jQuery(function (){
    initChosen();
  });
</script>