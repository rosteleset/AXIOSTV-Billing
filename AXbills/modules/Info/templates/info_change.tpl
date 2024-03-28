<form method='POST' class='form-horizontal' id='INFO_LOG'>
  <input type="hidden" name="index" value="%INDEX%">
  <input type="hidden" name="SAVE" value="1">
  <input type="hidden" name="ID" value="%ID%">
  <input type="hidden" name="UID" value="%UID%">

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{CHANGE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group'>
        <label class='control-label col-md-4 col-sm-3' for="COMMENTS_OLD">_{OLD}_ _{COMMENTS}_:</label>
        <div class='col-md-8 col-sm-9'>
          <input id="COMMENTS_OLD" name="COMMENTS_OLD" value="%TEXT%" class="form-control" type="text">
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-4 col-sm-3' for="COMMENTS">_{COMMENTS}_:</label>
        <div class='col-md-8 col-sm-9'>
          <input id="COMMENTS" name="COMMENTS" value="" placeholder="_{COMMENTS}_" class="form-control" type="text">
        </div>
      </div>
      <input class='btn btn-primary' type='submit' name="SAVE" value='_{SAVE}_'>
    </div>
  </div>
</form>
