<div class="btn-group">
    %QUICK_CMD%
</div>


<form action=$SELF_URL METHOD=post name=FORM_NAS class='form-horizontal'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='NAS_ID' value='%NAS_ID%'>
    <input type=hidden name='console' value='1'>
    <input type=hidden name='change'  value='%change%'>

    <div class='card card-primary card-outline box-big-form'>
      <div class='card-header with-border'>
        <h4 class='card-title'> _{MANAGE}_ </h4>
      </div>
      <div class='nav-tabs-custom card-body'>
        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='NAS_MNG_IP_PORT'>IP:PORT</label>
          <div class='col-sm-10'>
            <input id='NAS_MNG_IP_PORT' name='NAS_MNG_IP_PORT' value='%NAS_MNG_IP_PORT%'
              class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='NAS_MNG_USER'>_{USER}_</label>
          <div class='col-sm-10'>
            <input id='NAS_MNG_USER' name='NAS_MNG_USER' value='%NAS_MNG_USER%'
              class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='NAS_MNG_PASSWORD'>_{PASSWD}_</label>
          <div class='col-sm-10'>
            <input id='NAS_MNG_PASSWORD' name='NAS_MNG_PASSWORD' value='%NAS_MNG_PASSWORD%'
              class='form-control' type='password' autocomplete='new-password'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label'>_{TYPE}_</label>
          <div class='col-sm-10'>
            %TYPE_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label'>_{COMMENTS}_</label>
          <div class='col-sm-10'>
            <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label'>CMD</label>
          <div class='col-sm-10'>
            <textarea class='form-control' id='CMD' name='CMD' rows='3' placeholder='CMD'>%CMD%</textarea>
          </div>
        </div>

        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='ACTION' value='_{SEND}_'>
            <label class='checkbox-inline float-right'><input type='checkbox' name='SAVE' value='1'><strong>_{SAVE}_</strong></label>
        </div>
      </div>
    </div>
</form>

<script>
  jQuery(function () {
    var removeBtns = jQuery('.removeIpBtn');
    var saveBtn    = jQuery('.export-btn');

    function removeAddress(context) {
      var cont = jQuery(context);

      var command = "/ip firewall address-list remove numbers=" + cont.attr('data-address-number');

      var params = {
        qindex : '$index',
        console: 1,
        full   : 1,
        header : 2,
        ACTION : 1,
        NAS_ID : '$FORM{NAS_ID}',
        CMD    : command
      };

      cont.find('.fa').addClass('fa-spin');

      jQuery.get(SELF_URL, params, function () {
        cont.parent().parent().hide();
      });

    }

    function exportText() {
      var fullText = "";
      var rows = jQuery('#CONSOLE_RESULT_ > tbody > tr > td');
      jQuery.each(rows, function( index, value ) {
        fullText = fullText + jQuery(value).text() + "\n";
      });

      var blob = new Blob([fullText], {type: "text/plain;charset=utf-8"});
      var link = window.URL.createObjectURL(blob);
      // window.location = link;
      var a = document.createElement("a");
      a.href = link;
      a.download = "mikrotik.txt";
      document.body.appendChild(a);
      a.click();
    };

    removeBtns.on('click', function () {
      removeAddress(this);
    });

    saveBtn.on('click', function (e) {
      e.preventDefault();
      exportText();
    });

  })
</script>

