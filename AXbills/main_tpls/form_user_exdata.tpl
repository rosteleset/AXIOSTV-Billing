<input type='hidden' name='UID' value='$FORM{UID}'/>

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
            <div class='text-center'> <!-- %DISABLE% -->
              <div class='custom-control custom-switch custom-switch-on-danger custom-switch-off-success pl-0'>
                %FORM_DISABLE%
              </div>
            </div>
            <input class='form-control mt-2' type='text' name='ACTION_COMMENTS' ID='ACTION_COMMENTS' value='%DISABLE_COMMENTS%' size='40'
                   style='display: none; height: calc(2rem)' />
          </div>
        </div>
      </div>
    </div>
</div>

<!--
<div class='form-group row'>
  <label  class='col-sm-2 col-form-label' for='LOGIN'>_{LOGIN}_</label>
  <div class='col-sm-10'>
    <input id='LOGIN' name='LOGIN' value='%LOGIN%' data-check-for-pattern='%LOGIN_PATTERN%' readonly class='form-control' type='text'>
  </div>
</div>
-->

<div class='form-group row'>
  <label class='col-sm-2 col-form-label' for='GRP'>_{GROUPS}_</label>
  <div class='col-sm-10'>
    <div class='input-group'>
      <input type='text' name='GRP' value='%GID%:%G_NAME%' ID='GRP' %GRP_ERR% class='form-control' readonly='readonly'/>
      <div class='input-group-append'>
        <a class='btn input-group-button' href='$SELF_URL?index=12&UID=$FORM{UID}'>
          <i class='fa fa-pencil-alt'></i>
        </a>
      </div>
    </div>
  </div>
</div>

<script>
  jQuery(function (){
    initChosen();
  });
</script>