<script src='/styles/default/js/raphael.min.js'></script>
<script src='/styles/default/js/build_construct.js'></script>

<style type='text/css'>
   #tip {
    position: fixed;
    color: white;
    border: 1px solid gray;
    border-bottom: none;
    background-color: #7AB932;
    padding: 3px;
    z-index: 1000;
    /* set this to create word wrap */
    max-width: 200px;
  }

   .dom-control-panel {
		 padding: 6px 10px 6px 6px;
		 color: #333;
		 background: #fff;
		 position: absolute;
     top: 10px;
     right: 20px;
     z-index: 999;
		 box-shadow: 0 1px 5px rgb(0 0 0);
		 border-radius: 5px;
   }
</style>

<form method='post' class='form form-horizontal'>
  <div class='card card-primary card-outline no-padding'>
    <div class='card-header with-border'>
      <h4 class='card-title'>%DISTRICT_NAME% %STREET_NAME% %BUILD_NAME%</h4>
    </div>
    <div class='card-body no-padding' id='body'>
      <div class='info-box-content'>
        <div class='col-md-12 text-center'>
          <p><b>_{ENTRANCES}_:</b> %BUILD_ENTRANCES%</p>
          <p><b>_{FLORS}_:</b> %BUILD_FLORS%</p>
          <p><b>_{MAP}_ _{FLATS}_: </b><span id='clients'></span>/%BUILD_FLATS% </p>
        </div>

          <div class='col-md-12 p-0 pr-2'>
          <div class='progress'>
            <div class='progress-bar'>
              <span class='badge bg-light-blue-active color-palette' id='progress-bar'></span>
            </div>
          </div>
        </div>
	</div>
      <!-- Canvas -->
      <div class='col-sm-12 p-0' id='scroll_canvas_container'>
        <div class='form-group dom-control-panel'>
          <div class='form-check'>
            <input class='form-check-input' type='radio' id='user-radio' name='range' value='user' checked>
            <label class='form-check-label' for='user-radio'>_{USERS}_</label>
          </div>
          <div class='form-check'>
            <input class='form-check-input' type='radio' id='internet-radio' name='range' value='internet'>
            <label class='form-check-label' for='internet-radio'>Internet</label>
          </div>
          <div class='form-check'>
            <input class='form-check-input' type='radio' id='iptv-radio' name='range' value='iptv'>
            <label class='form-check-label' for='iptv-radio'>IPTV</label>
          </div>
          <div class='form-check'>
            <input class='form-check-input' type='radio' id='cams-radio' name='range' value='cams'>
            <label class='form-check-label' for='cams-radio'>Cams</label>
          </div>
          <div class='form-check'>
            <input class='form-check-input' id='pon-radio' type='radio' name='range' value='pon'>
            <label class='form-check-label' for='pon-radio'>PON</label>
          </div>
        </div>

        <div id='tip' style='display: none'></div>
        <div id='canvas_container' class='w-100 p-0' style='overflow: scroll;'>
        </div>
        <div>
          <p class='text-center'>
            <strong><i class='col-md-12 fa fa-list margin-r-5'></i>_{DESCRIBE}_</strong>
            <span class='badge badge-success'>_{ENABLE}_</span>
            <span class='badge badge-danger'>_{NEGATIVE}_ _{DEPOSIT}_</span>
            <span class='badge badge-warning'>_{CREDIT}_</span>
            <span class='badge badge-secondary'>_{DISABLED}_</span>
          </p>
        </div>
        %TABLE_NAS%
      </div>

    </div>
  </div>


</form>

<script type='application/javascript'>
  jQuery(document).ready(function () {

    let percentages = {
      user: '%USER_PERCENTAGE%',
      internet: '%INTERNET_PERCENTAGE%',
      iptv: '%IPTV_PERCENTAGE%',
      cams: '%CAMS_PERCENTAGE%',
      pon: '%PON_PERCENTAGE%'
    }
	
	let clients = {
      user: '%CLIENTS_FLATS_SUM%',
      internet: '%INTERNET_CLIENTS_FLATS_SUM%',
      iptv: '%IPTV_CLIENTS_FLATS_SUM%',
      cams: '%CAMS_CLIENTS_FLATS_SUM%',
      pon: '%PON_CLIENTS_FLATS_SUM%'
    }

    let info = {
      user: '%USER_INFO%',
      internet: '%INTERNET_INFO%',
      iptv: '%IPTV_INFO%',
      cams: '%CAMS_INFO%',
	  pon: '%PON_INFO%'
    }

    jQuery("input[name='range']").on('click', function() {
      let type = jQuery(this).val();

      setView(type);
    });

    function setView(type) {
      jQuery('.progress-bar').width(percentages[type]);
      jQuery('#progress-bar').text(percentages[type]);
      jQuery('#clients').text(clients[type]);
      jQuery('#no_correct_flat').attr('href', '%SHOW_USERS%');

      jQuery('#canvas_container').html('');
      build_construct(
        '%BUILD_FLORS%',
        '%BUILD_ENTRANCES%',
        '%FLORS_ROOMS%',
        'canvas_container',
        info[type],
        '%LANG_PACK%',
        'canvas_height',
        '%BUILD_FLATS%',
        '%BUILD_SCHEMA%',
        '%NUMBERING_DIRECTION%',
        '%START_NUMBERING_FLAT%'
      );
    }

    setView('user');
  })
</script>


