<script TYPE='text/javascript'>
  <!--
  function add_comments() {

    var DISPATCH_CREATE = document.getElementById('DISPATCH_CREATE');

    if (DISPATCH_CREATE.checked) {
      DISPATCH_CREATE.checked = false;
      var comments = prompt('_{COMMENTS}_', '');

      var new_dispatch = document.getElementById('new_dispatch');
      var dispatch_list = document.getElementById('dispatch_list');
      var DISPATCH_COMMENTS = document.getElementById('DISPATCH_COMMENTS');

      if (comments === '' || comments === null) {
        alert('Enter comments');
        DISPATCH_CREATE.checked = false;
        new_dispatch.style.display = 'none';
        dispatch_list.style.display = 'block';
      }
      else {
        DISPATCH_CREATE.checked = true;
        DISPATCH_COMMENTS.value = comments;
        new_dispatch.style.display = 'block';
        dispatch_list.style.display = 'none';
      }
    }
    else {
      DISPATCH_CREATE.checked = false;
      DISPATCH_COMMENTS.value = '';
      new_dispatch.style.display = 'none';
      dispatch_list.style.display = 'block';
    }
  }

  function add_delivery() {

    var DELIVERY_CREATE = document.getElementById('DELIVERY_CREATE');

    if (DELIVERY_CREATE.checked) {
      DELIVERY_CREATE.checked = false;
      var comments = prompt('_{SUBJECT}_', '');

      var new_delivery = document.getElementById('new_delivery');
      var delivery_list = document.getElementById('delivery_list');
      var DELIVERY_COMMENTS = document.getElementById('DELIVERY_COMMENTS');

      if (comments === '' || comments === null) {
        alert('Enter comments');
        DELIVERY_CREATE.checked = false;
        new_delivery.style.display = 'none';
        delivery_list.style.display = 'block';
      }
      else {
        DELIVERY_CREATE.checked = true;
        DELIVERY_COMMENTS.value = comments;
        new_delivery.style.display = 'block';
        delivery_list.style.display = 'none';
      }
    }
    else {
      DELIVERY_CREATE.checked = false;
      DELIVERY_COMMENTS.value = '';
      new_delivery.style.display = 'none';
      delivery_list.style.display = 'block';
    }
  }

  -->
</script>

<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'
      class='form-horizontal'>
  <!-- <legend>_{MESSAGES}_</legend> -->
  <fieldset>

    <div class='card card-primary card-outline box-big-form'>
      <div class='card-header with-border'><h4 class='card-title'>_{TASK}_</h4></div>
      <div class='card-body'>

        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='add_form' value='1'/>
        <!-- <input type='hidden' name='UID' value='$FORM{UID}'/> -->
        <input type='hidden' name='ID' value='%ID%'/>
        <input type='hidden' name='PAR' value='%PAR%'/>
        <input type='hidden' name='step' value='$FORM{step}'/>
        <input type='hidden' name='TASK' value='$FORM{TASK}'/>

        <div class='form-group'>
          <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_</label>

          <div class='col-md-9'>
            <input type='text' name='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%'
                   class='form-control'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='COMMENTS'>_{MESSAGE}_</label>

          <div class='col-md-9'>
            <textarea class='form-control' id='MESSAGE' name='MESSAGE' rows='3'>%MESSAGE%</textarea>
          </div>
        </div>
      </div>

      %SEND_EXTRA_FORM%
      %SEND_DELIVERY_FORM%

      <div class="card card-primary card-outline box-big-form collapsed-box">
        <div class="card-header with-border">
          <h4 class="card-title">_{ADDITIONALLY}_</h4>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-box-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>

        <div id='nas_misc' class='card-body'>

          <div class='form-group'>
            <label class='control-label col-md-3' for='INNER_MSG'>_{PRIVATE}_</label>

            <div class='col-md-6'>
              <input type='checkbox' name='INNER_MSG' value='1' %INNER_MSG%>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>

            <div class='col-md-6'>
              <input id='DATE' type='text' name='DATE' value='%DATE%' class='datepicker form-control'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='FILE_UPLOAD_1'>_{ATTACHMENT}_ 1</label>

            <div class='col-md-6'>
              <input type='file' name='FILE_UPLOAD_1' ID='FILE_UPLOAD_1' value='%FILE_UPLOAD%'
                     placeholder='%FILE_UPLOAD%' class='form-control'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='FILE_UPLOAD_2'>_{ATTACHMENT}_ 2</label>

            <div class='col-md-6'>
              <input type='file' name='FILE_UPLOAD_2' ID='FILE_UPLOAD_2' value='%FILE_UPLOAD%'
                     placeholder='%FILE_UPLOAD%' class='form-control'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='STATE'>_{STATE}_</label>

            <div class='col-md-9'>
              %STATE_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='PRIORITY'>_{PRIORITY}_</label>

            <div class='col-md-9'>
              %PRIORITY_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='RESPOSIBLE'>_{RESPOSIBLE}_</label>

            <div class='col-md-9'>
              %RESPOSIBLE%
            </div>
          </div>

          <div class='form-group'>
            <label class='col-sm-4 col-md-3' for='PLAN_TIME'>_{EXECUTION}_:</label>
            <div class='col-sm-8 col-md-9'>
              <input type='hidden' value='%PLAN_TIME%' name='PLAN_TIME' id='PLAN_TIME'/>
              <input type='hidden' value='%PLAN_DATE%' name='PLAN_DATE' id='PLAN_DATE'/>
              %PLAN_DATETIME_INPUT%
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='DISPATCH'>_{DISPATCH}_</label>

            <div class='col-md-9' id=dispatch_list>

              <div class='input-group'>
                        <span class='input-group-addon'>
                          _{ADD}_ <input type='checkbox' id=DISPATCH_CREATE name=DISPATCH_CREATE value=1
                                         onClick='add_comments();' title='_{CREATE}_ _{DISPATCH}_'>
                        </span>
                %DISPATCH_SEL%
              </div>
            </div>

            <div id=new_dispatch style='display: none'>
              <div class='col-md-5'>
                <input type=text id=DISPATCH_COMMENTS name=DISPATCH_COMMENTS value='%DISPATCH_COMMENTS%'
                       class='form-control'>
              </div>
              <label class='control-label col-md-2' for='DISPATCH_PLAN_DATE'>_{DATE}_:</label>
              <div class='col-md-2'>
                <input id='DISPATCH_PLAN_DATE' type='text' name='DISPATCH_PLAN_DATE' value='%DISPATCH_PLAN_DATE%'
                       class='datepicker form-control'>
              </div>
            </div>

          </div>

          <div class='form-group'>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='SURVEY'>_{TEMPLATES}_ (_{SURVEY}_)</label>

            <div class='col-md-9'>
              %SURVEY_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for=''>_{PHONE}_</label>

            <div class='col-md-9'>
              <div class='input-group'>
                <div class='input-group-addon'>
                  <i class='fa fa-phone'></i>
                </div>
                <input class='form-control' name='CALL_PHONE' value='%CALL_PHONE%' placeholder='%CALL_PHONE%'
                       data-inputmask='{"mask" : "(999) 999-9999", "removeMaskOnSubmit" : true}' type="text"/>
              </div>
            </div>

          </div>

        </div>
      </div>
      <div class="card card-primary card-outline box-big-form collapsed-box">
        <div class="card-header with-border">
          <h4 class="card-title">_{SHEDULE}_</h4>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-box-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='row'>
            <div class='col-md-2'>day</div>
            <div class='col-md-2'>month</div>
            <div class='col-md-2'>year</div>
          </div>
          <div class='row'>
            <div class='col-md-2'><input class='form-control' name='DAY' value='%DAY%'></div>
            <div class='col-md-2'><input class='form-control' name='MONTH' value='%MONTH%'></div>
            <div class='col-md-2'><input class='form-control' name='YEAR' value='%YEAR%'></div>
            <div class='col-md-4'>
              <div class='checkbox'>
                <label><input type='checkbox' name=PERIODIC value='1' %PERIODIC%>_{PERIODICALLY}_</label>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='card-footer'>
        %BACK_BUTTON%
        <!--Should stay on single line-->
        <input type='submit' name='%ACTION%' class='btn btn-primary' value='%LNG_ACTION%' id='go' title='Ctrl+Enter'/>
      </div>
    </div>
  </fieldset>

</FORM>

