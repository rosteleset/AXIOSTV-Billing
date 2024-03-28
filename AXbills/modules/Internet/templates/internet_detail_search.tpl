<div class="col-md-6 col-xs-12">
  <div class='card card-primary card-outline box-form'>
    <div class='card-body'>

    <div class='form-group'>
      <label class='control-label col-md-5' for='SRC_IP'>SRC IP: (192.168.0.1,192.168,10.0/24)</label>
        <div class='col-md-4'>
          <input id='SRC_IP' name='SRC_IP' value='%SRC_IP%' placeholder='%SRC_IP%' class='form-control' type='text'>
        </div>
  <label class='control-label col-md-2' for='SRC_IP'>_{GROUP}_:</label>
  <div class='col-md-2'>
    <input type=checkbox name=SRC_IP_GROUP value='1' %SRC_IP_GROUP%>
    </div>
      </div>

  <div class='form-group'>
  <label class='control-label col-md-5' for='DST_IP'>DST IP: (192.168.0.1,192.168,10.0/24)</label>
        <div class='col-md-4'>
          <input id='DST_IP' name='DST_IP' value='%DST_IP%' placeholder='%DST_IP%' class='form-control' type='text'>
        </div>
  <label class='control-label col-md-2' for='DST_IP'>_{GROUP}_:</label>
  <div class='col-md-2'>
    <input type=checkbox name=DST_IP_GROUP value='1' %DST_IP_GROUP%>
    </div>
      </div>

  <div class='form-group'>
  <label class='control-label col-md-5' for='RESOLVE'>Resolve:</label>
  <div class='col-md-2'>
    <input type=checkbox name=RESOLVE value='1' %RESOLVE%>
    </div>
      </div>

  </div>
  </div>

</div>