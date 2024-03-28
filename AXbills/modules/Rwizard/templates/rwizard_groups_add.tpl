<form action='$SELF_URL' method='POST' class='form-horizontal'>
<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value=%ID%>

  <div class='card box-form box-primary'>
    <div class='card-header with-border'>_{GROUPS}_</div>
    <div class='card-body'>
      <div class='form-group'>
        <label class='control-element col-md-3'>_{GROUP}_</label>
        <div class='col-md-9'>
          <input class='form-control' name='NAME' value='%NAME%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-element col-md-3'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3' for='ADMINS'>_{ADMINS}_</label>
        <div class='col-md-9'>
          <input type='hidden' id='ADMINS' name='ADMINS' value=''>
          <button type='button' class='btn btn-primary float-left' data-toggle='modal' data-target='#myModal'
                  onClick='return openModal()'>_{SELECTED}_: <span class='admin_count'></span></button>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
    </div>
  </div>

  <!-- Modal -->
  <div class='modal fade' id='myModal' role='dialog'>
    <div class='modal-dialog'>
    
      <!-- Modal content-->
      <div class='modal-content'>
        <div class='modal-header'>
          <h4 class='modal-title'>_{ADMINS}_</h4>
          <button type='button' class='close' data-dismiss='modal'>&times;</button>
        </div>
        <div class='modal-body'>
         %ADMINS_LIST%
        </div>
        <div class='modal-footer'>
          <button type='button' class='btn btn-primary' data-dismiss='modal' onClick='return closeModal()'>_{CLOSE}_</button>
        </div>
      </div>
      
    </div>
  </div>

</form>

<script type='text/javascript'>
  function closeModal() {
    var partcipiantsArr = [];
    jQuery( '.admin_checkbox' ).each(function() {
      if (this.checked) {
        partcipiantsArr.push(jQuery(this).attr('aid'));
      }
    });
    jQuery( '.admin_count' ).text(partcipiantsArr.length);
    document.getElementById('ADMINS').value = partcipiantsArr.join();
  }

  function setCheckboxes() {
    var partcipiantsList = document.getElementById('ADMINS').value;
    var partcipiantsArr = partcipiantsList.split(',');
    var count = 0;
    jQuery( '.admin_checkbox' ).each(function() {
      if ( partcipiantsArr.indexOf(jQuery(this).attr('aid')) >= 0 ) {
        jQuery(this).prop('checked', true);
        count++;
      }
      else {
        jQuery(this).prop('checked', false);
      }
    });
    jQuery( '.admin_count' ).text(count);
  }

  jQuery(function() {
    document.getElementById('ADMINS').value = '%ADMINS%';
    setCheckboxes();
  });
</script>