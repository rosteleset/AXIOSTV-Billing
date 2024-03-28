<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' id='DEFAULT_UNCLICK' name='DEFAULT_UNCLICK' value=''/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <div class='card-title'>
        %BUTTON_NAME% _{PAYMENT_METHOD}_
      </div>
    </div>

    <div class='card-body'>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='NEW_ID'>ID:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input %ALLOW_SET_ID% class='form-control' id='NEW_ID' name='NEW_ID' value='%ID%' type='text'>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='NAME'>_{NAME}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input class='form-control' id='NAME' required name='NAME' value='%NAME%' type='text'>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='COLOR'>_{COLOR}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input class='form-control' ID='COLOR' name='COLOR' value='%COLOR%' type='color'>
          </div>
        </div>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" type="checkbox" id="DEFAULT_PAYMENT" name="DEFAULT_PAYMENT" %CHECK_DEFAULT%
               value='1' data-tooltip='%ADMIN_PAY%'>
        <label for="DEFAULT_PAYMENT" class="custom-control-label">_{DEFAULT}_</label>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='FEES_TYPE'>_{FEES}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            %FEES_TYPE%
          </div>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input class='btn btn-primary pull-center' name='%BUTTON_LABALE%' value='%BUTTON_NAME%' type='submit'>
    </div>

  </div>

</form>

<script>
  jQuery(function () {
    jQuery('#DEFAULT_PAYMENT').change(function () {
      if (this.checked) {
        jQuery('#DEFAULT_UNCLICK').val('')
      } else {
        jQuery('#DEFAULT_UNCLICK').val('1')
      }
    });
  });
</script>