<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name=index value=$index>
  <div class='card card-primary card-outline box-form'>
    <!-- head -->
    <div class='card-header with-border'>
      <h4 class="card-title table-caption">_{SEND}_ Sms</h4>
    </div>
    <!-- body -->
    <div class='card-body'>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{PHONE}_</label>
        <div class="col-md-9">
          <input type="text" pattern="^[0-9]+" name="PHONE_NUMBER" class="form-control" required>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-sm-2 col-md-3' for='MESSAGE'>_{MESSAGE}_</label>
        <div class='col-sm-10 col-md-9'>
          <textarea class='form-control' id='MESSAGE' name='MESSAGE' rows='3' required></textarea>
        </div>
      </div>

    </div>
    <!-- footer -->
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>

  </div>
</form>
