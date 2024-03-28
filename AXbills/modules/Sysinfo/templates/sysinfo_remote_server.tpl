<script>
  jQuery(function () {
    var check_access_button = jQuery('button#check_server_access');
    var check_access_result = jQuery('div#check_server_result');
    var management_type     = jQuery('select#MANAGEMENT');

    var cached_server_info = {};

    var nas_id_input       = jQuery('input#NAS_ID');
    var name_input         = jQuery('input#NAME_id');
    var ip_input           = jQuery('input#IP_id');
    var port_input         = jQuery('input#PORT_id');
    var private_key_select = jQuery('select#PRIVATE_KEY');

    var satellite_management_port = '%SATELLITE_PORT%' || 19422;

//        if (!nas_id_input.length) alert('not found');


    // Make button active when have NAS_ID
    nas_id_input.on('change', function () {
      fillNasInfo(nas_id_input.val());
    });
    if (nas_id_input.val() && !(ip_input.val() && port_input.val())) {
      fillNasInfo(nas_id_input.val())
    }

    setInterval(
        function () {
          // Wait for both fields filled
          if (!ip_input.val() || !port_input.val()) {
            check_access_button.prop('disabled', true);
          }
          else {
            check_access_button.prop('disabled', false);
          }
        },
        1000
    );

    management_type.on('change', function () {
      var type = jQuery(this).val();

      if (+type === 0 && nas_id_input.val()) {
        fillNasInfo(nas_id_input.val());
      }
      else if (+type === 1) {
        port_input.val(satellite_management_port);
      }

    });


    check_access_button.on('click', function () {
      checkServerAccess(management_type.val(), function(res){
        check_access_result.html(res)
      })
    });

    function getNasInfo(nas_id, callback) {
      if (cached_server_info[nas_id]) {
        callback(cached_server_info[nas_id]);
      }
      jQuery.getJSON('/admin/index.cgi?qindex=' + INDEX + '&header=2&nas_info=1&NAS_ID=' + nas_id, function (data) {
        cached_server_info[nas_id] = data;
        callback(data);
      });
    }

    function fillNasInfo(nas_id) {
      getNasInfo(nas_id, function (info) {
        console.log(info);
        name_input.val(info.name);
        ip_input.val(info.ip);
        port_input.val(info.ssh_port);
      });
    }

    function checkServerAccess(management_type, callback) {
      jQuery.getJSON('/admin/index.cgi?qindex=' + INDEX
          + '&nas_check_access=' + management_type
          + '&IP=' + ip_input.val()
          + '&PORT=' + port_input.val()
          + '&PRIVATE_KEY=' + private_key_select.val(),
          function (data) {
            var status      = data.status;
            var description = data.description;

            var text_class = (status === 1) ? 'text-success' : 'text-danger';

            callback('<span class="' + text_class + '">' + description + '</span>');
          });
    }

  });

</script>

<form name='SYSINFO_REMOTE' id='form_SYSINFO_REMOTE' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{REMOTE_SERVERS}_</h4>
    </div>
    <div class='card-body'>

      <div class="bg-info">
        <div class='form-group'>
          <label class='control-label col-md-3' for='NAS_ID'>_{NAS}_</label>
          <div class='col-md-9'>
            %NAS_ID_SELECT%
            <p class='help-block'>_{COPY_FROM_NAS_SERVER}_</p>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='MANAGEMENT'>_{MANAGEMENT}_</label>
        <div class='col-md-9'>
          %MANAGEMENT_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_ID'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='IP_ID'>IP</label>
        <div class='col-md-9'>
          <input type='text' class='form-control ip-input' value='%IP%' required name='IP' id='IP_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='PORT_ID'>_{PORT}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%PORT%' required name='PORT' id='PORT_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='PRIVATE_KEY'>_{PRIVATE_KEY}_</label>
        <div class='col-md-9'>
          %PRIVATE_KEY_SELECT%
        </div>
      </div>


      <div class='form-group hidden'>
        <div class='col-md-6'>
          <button type='button' class='btn btn-secondary' disabled='disabled' id='check_server_access'>_{CHECK_ACCESS}_
          </button>
        </div>
        <div class='col-md-6' id='check_server_result'></div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_ID'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control col-md-9' rows='5' name='COMMENTS' id='COMMENTS_ID'>%COMMENTS%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <div class='card card-primary card-outline'>
          <div class='card-header with-border' role='tab' id='EXTRA_heading'>
            <h4 class='card-title text-center'>
              <a role='button' data-toggle='collapse' href='#EXTRA_collapse' aria-expanded='true'
                 aria-controls='EXTRA_collapse'>
                _{EXTRA}_
              </a>
            </h4>
          </div>
          <div id='EXTRA_collapse' class='card-collapse collapse' role='tabpanel' aria-labelledby='EXTRA_heading'>
            <div class='card-body'>

              <div class='checkbox text-center'>
                <label>
                  <input type='checkbox' data-return='1' data-checked='%NAT%' name='NAT' id='NAT_ID'/>
                  <strong>_{BEHIND}_ NAT</strong>
                </label>
              </div>
            </div> <!-- end of collapse panel-body -->
          </div> <!-- end of collapse div -->
        </div> <!-- end of collapse panel -->
      </div> <!-- end of collapse form-group -->

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>

</form>


