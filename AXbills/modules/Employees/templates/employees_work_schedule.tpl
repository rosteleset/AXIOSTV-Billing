<form method='POST' class='form-horizontal container-md'>

<input type='hidden' name='AID' value='$FORM{AID_SCHEDULE}'>
<input type='hidden' name='index' value='$index'>

<div class='card card-primary card-outline box-form '>
  <div class='card-header with-border'><h4 class='card-title'>%FIO%</h4></div>
  <div class='card-body'>
    <ul class='nav nav-tabs' role='tablist'>
      <li class='nav-item active'>
        <a href='#monthly' class="nav-link active" role='tab' data-toggle='tab'>_{MONTHLY}_</a>
      </li>
      <li class="nav-item">
        <a href='#hourly' class="nav-link" role='tab' data-toggle='tab'>_{HOURLY}_</a>
      </li>
      <!-- <li>
        <a href='#other' role='tab' data-toggle='tab'>Other</a>
      </li> -->
    </ul>

    <div class='tab-content'>
      <div class='active tab-pane' id='monthly'>
      <input type='hidden' name='TYPE' value='1'>
        <div class='form-group row'>
          <label class='col-md-3 control-label'>_{BET}_</label>
          <div class='col-md-9'>
            <input type='text' name='BET' value='%BET%' class='form-control'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label'>_{BET_OVERTIME}_</label>
          <div class='col-md-9'>
            <input type='text' name='BET_OVERTIME' value='%BET_OVERTIME%' class='form-control'>
          </div>
        </div>
      </div>


      <div class='tab-pane' id='hourly'>
        <input type='hidden' name='TYPE' value='2'>
        <hr>
        <div class='form-group row'>
          <label class='col-md-3 control-label'>_{BET_PER_HOUR}_</label>
          <div class='col-md-9'>
            <input type='text' name='BET_PER_HOUR' value='%BET_PER_HOUR%' class='form-control'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label'>_{BET_OVERTIME}_</label>
          <div class='col-md-9'>
            <input type='text' name='BET_OVERTIME' value='%BET_OVERTIME%' class='form-control'>
          </div>
        </div>
      </div>

      <div class='tab-pane' id='other'>
        <input type='hidden' name='TYPE' value='3'>
        Смешаная
      </div>
    </div>
  </div>
  <div class='card-footer'>
    <input class='btn btn-primary' type='submit' name='%ACTION%' value='%ACTION_LNG%'/>
  </div>
</div>

</form>

<script>
    function disableInputs(context) {
        var j_context = jQuery(jQuery(context).attr('href'));

        j_context.find('input').prop('disabled', true);
        j_context.find('select').prop('disabled', true);

        updateChosen();
    }

    function enableInputs(context) {
        var j_context = jQuery(jQuery(context).attr('href'));

        j_context.find('input').prop('disabled', false);
        j_context.find('select').prop('disabled', false);

        updateChosen();
    }


    jQuery(function () {
        jQuery('a[data-toggle=\"tab\"]').on('shown.bs.tab', function (e) {
            enableInputs(e.target);
            disableInputs(e.relatedTarget);
        })
    });


</script>