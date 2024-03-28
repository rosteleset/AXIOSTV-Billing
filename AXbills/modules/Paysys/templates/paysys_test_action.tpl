<div class='col-md-8 col-md-offset-2'>

  <form id='%ACTION%Form'>
    <input type='hidden' name='qindex' value='%INDEX%'>
    <input type='hidden' name='header' value='2'>
    <input type='hidden' name='module' value='%MODULE%'>
    <input type='hidden' name='_action' value='%ACTION%'>
    <input type='hidden' name='headers' value='%HEADERS%'>

    <div class='card card-primary card-outline'>
      <div class='card-header with-border'><h4 class='card-title'>%ACTION% %MODULE%</h4></div>
      <div class='card-body'>

        %INPUTS%

        <div class='form-group row'>
          <label class='col-md-3 control-label' for='DEBUG'>_{DEBUG}_</label>
          <div class='col-md-9 mt-2'>
            %SELECT_DEBUG%
          </div>
        </div>
      </div>
      <div class='card-footer'>
        <button id='%ACTION%Submit' type='button' class='btn btn-primary'>_{START_PAYSYS_TEST}_</button>
      </div>

    </div>
  </form>
  <div class='card card-primary card-outline' id='%ACTION%Box' style='display: none'>
    <div class='card-body' id='%ACTION%Results'></div>
  </div>

  <script>
    jQuery(function () {
      jQuery('#%ACTION%Submit').on('click', function () {
        let data = jQuery('#%ACTION%Form').serialize();

        jQuery.post('/admin/index.cgi', data, function (result) {
          jQuery('#%ACTION%Results').html(result);
          jQuery('#%ACTION%Box').show();
        });

      });

    });
  </script>

</div>
