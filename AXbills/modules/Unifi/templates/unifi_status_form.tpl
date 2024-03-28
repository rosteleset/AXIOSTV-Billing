<noscript>
  <form name='logout-form' method='post'>
    <input type='hidden' name='operation_type' value='logout'>
    <input type='hidden' name='id' value='%USERMAC%'>
    <input type='submit' role='button' class='form-control btn btn-ls btn-danger' value='_{HANGUP}_'/>
  </form>
</noscript>

<div class='row'>
  <div class='col-md-6 col-md-push-3 col-xs-12'>
    <div class='row well well-sm text-center'>
      <div class='col-md-9'>
        <label class='contol-label control-element col-md-5' for='refresh_time' style='margin: 10px 0 5px;'>_{REFRESH}_</label>
        <div class='col-md-7'>
          <select name='REFRESH_TIME' class='form-control text-center' id='refresh_time' style='margin: 5px 0;'></select>
        </div>
      </div>
      <div class='col-md-3'>
        <button role='button' class='btn btn-success' id='refresh_now_btn' style='margin: 5px 0;'>_{NOW}_</button>
      </div>
    </div>
  </div>

</div>


<div id='status-content'>
  <div class='text-center'>
    <span class='fa fa-spinner fa-spin fa-2x'></span>
  </div>
</div>

</div>

<script>

  jQuery(function () {

    aAuthentificator.setMac('%USERMAC%');
    aAuthentificator.setApMac('%APMAC%');

    aAuthentificator.updateStatus({
      "status"     : "2",
      "signal"     : "%SIGNAL%",
      "transmitted": "%TRANSMITTED%",
      "received"   : "%RECEIVED%",
      "timeleft"   : "%TIME%",
      "speedDown"  : "%DOWN%",
      "speedUp"    : "%UP%",
      "userIP"     : "%USERIP%",
      "userName"   : "%USERNAME%",
      "userMAC"    : "%USERMAC%"
    });

    var refreshtime_select = jQuery('select#refresh_time');
    var refresh_now_btn = jQuery('#refresh_now_btn');

    var refresh_times = [60, 120, 300, 600];

    moment.locale(lang["MOMENT_LOCALE"]);

    var options_text = '';
    jQuery.each(refresh_times, function (i, e) {
      options_text += '<option value="' + e + '">' + moment.duration(e, 'seconds').humanize(true) + '</option>';
    });
    refreshtime_select.html(options_text);

    refreshtime_select.on('change', function () {
      aAuthentificator.setRefreshTimeout(this.value);
    });

    refresh_now_btn.on('click', aAuthentificator.requestUpdate);
  });

</script>