<!-- Button trigger modal -->
<button type='button' class='btn btn-primary btn-sm' data-toggle='modal' data-target='#myModal'>
  _{CONTINUE}_ _{ACCESS}_
</button>

<!-- Modal -->
<form id='SHARING_CONTINUE'>
  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='UID' value=$FORM{UID}>
  <div class='modal fade' id='myModal' tabindex='-1' role='dialog' aria-labelledby='myModalLabel'>
    <div class='modal-dialog' role='document'>
      <div class='modal-content'>
        <div class='modal-header'>
          <h4 class='modal-title' id='myModalLabel'>_{CONTINUE}_ _{ACCESS}_</h4>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
              aria-hidden='true'>&times;</span></button>
        </div>
        <div class='modal-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='DATE'>_{DATE}_</label>
            <div class='col-md-9'>
              <input type='text' id='DATE' name='DATE' value='%DATE%' class='form-control datepicker' required>
            </div>
          </div>

        </div>
        <div class='modal-footer'>
          <button type='submit' name='CONTINUE' class='btn btn-primary' value='CONTINUE'>_{CHANGE}_</button>
        </div>
      </div>
    </div>
  </div>
</form>


