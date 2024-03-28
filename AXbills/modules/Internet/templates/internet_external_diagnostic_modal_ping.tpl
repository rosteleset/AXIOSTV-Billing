<input type=hidden name='%INDEX_OR_QINDEX%' value='%INDEX%'>
<input type=hidden name='diagnostic' value='%DIAGNOSTIC%'>
<input type=hidden name='UID' value='%UID%'>

<div class='form-group row'>
  <label class='col-md-6 col-form-label text-md-right' for='PACKET_SIZE'>_{PACKET_SIZE}_:</label>
  <div class='col-md-6'>
    <input id='PACKET_SIZE' name='PACKET_SIZE' type='number' min='0' max='65507' value='56' class='form-control'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-md-6 col-form-label text-md-right' for='PACKET_COUNT'>_{PACKET_COUNT}_:</label>
  <div class='col-md-6'>
    <input id='PACKET_COUNT' name='PACKET_COUNT' type='number' min='1' max='10' value='5' class='form-control'>
  </div>
</div>
