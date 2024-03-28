<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='%ID%'>
<div class='card card-primary card-outline'>
  <div class='card-header with-border'><h3 class='card-title'>%TYPE_NAME% : %NAME%</h3>
    <div class='card-tools float-right'>
      %INFO%
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body' id='task_form_body'>
    <div class='row'>
      <div class='col-md-9'>
        <h4>%DESCR%</h4>
        <hr>
        <p>_{RESPONSIBLE}_: %RESPONSIBLE_NAME%</p>
        <p>_{DUE_DATE}_: %CONTROL_DATE%</p>
        <p>_{CREATOR}_: %ADMIN_NAME%</p>
        <p %HIDE_PARTCIPIANTS%>
          <button type='button' class='btn btn-default btn-xs' data-toggle='modal' data-target='#myModal1'
                  onClick='return openModal()'>_{PARTCIPIANTS}_: <span class='admin_count'></span></button>
        </p>
        <input type='hidden' id='PARTCIPIANTS_LIST' name='PARTCIPIANTS_LIST' value='%PARTCIPIANTS_LIST%'>
      </div>
      <div class='col-md-3'>
        %PLUGINS_HTML%
      </div>
    </div>
  </div>

  <!-- Modal -->
  <div class='modal fade' id='myModal1' role='dialog'>
    <div class='modal-dialog'>

      <!-- Modal content-->
      <div class='modal-content'>
        <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal'>&times;</button>
          <h4 class='modal-title'>_{PARTCIPIANTS}_</h4>
        </div>
        <div class='modal-body'>
          %PARTCIPIANTS%
        </div>
        <div class='modal-footer'>
          <button type='button' class='btn btn-default' data-dismiss='modal' onClick='return closeModal()'>Close
          </button>
        </div>
      </div>

    </div>
  </div>

  <div class='card-footer'>
    <button type='button' class='btn btn-primary' data-toggle='modal' data-target='#myModal'>_{CLOSE_TASK}_</button>
  </div>
</div>

<!-- Modal -->
<div class='modal fade' id='myModal' role='dialog'>
  <div class='modal-dialog'>

    <!-- Modal content-->
    <div class='modal-content'>
      <div class='modal-header'>
        <h4 class='modal-title'>_{CLOSE_TASK}_</h4>
        <button type='button' class='close' data-dismiss='modal'>&times;</button>
      </div>
      <div class='modal-body'>
        <div class='row'>
          <div class='form-group row'>
            <div class='col-md-12'><p>_{COMMENTS}_:</p></div>
            <div class='col-md-12'>
              <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS'></textarea>
            </div>
          </div>
        </div>
      </div>
      <div class='modal-footer'>
        <input type='submit' name='done' value='_{DONE}_' class='btn btn-success'>
        <input type='submit' name='undone' value='_{UNDONE}_' class='btn btn-danger'>
      </div>
    </div>

  </div>
</div>

<script type='text/javascript'>
  function closeModal() {
    var responsibleArr = [];
    jQuery('.admin_checkbox').each(function () {
      if (this.checked) {
        responsibleArr.push(jQuery(this).attr('aid'));
      }
    });
    jQuery('.admin_count').text(responsibleArr.length);
    document.getElementById('PARTCIPIANTS_LIST').value = responsibleArr.join();
  }

  function setCheckboxes() {
    var responsibleList = document.getElementById('PARTCIPIANTS_LIST').value;
    var responsibleArr = responsibleList.split(',');
    var count = 0;
    jQuery('.admin_checkbox').each(function () {
      if (responsibleArr.indexOf(jQuery(this).attr('aid')) >= 0) {
        jQuery(this).prop('checked', true);
        count++;
      }
    });
    jQuery('.admin_count').text(count);
  }

  jQuery(function () {
    setCheckboxes();
  });
</script>