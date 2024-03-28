<link href='/styles/default/css/client.css' rel='stylesheet'>

<FORM action='$SELF_URL' METHOD=POST ID='REGISTRATION' class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=DOMAIN_ID value=$FORM{DOMAIN_ID}>
<input type=hidden name=module value=Dv>

<div class='card card-primary card-outline box-form center-block'>

<div class='card-header with-border'><h4 class='card-title'>_{REGISTRATION}_</h4></div>
<div class='card-body'>
%CHECKED_ADDRESS_MESSAGE%
<div class='form-group'>
  <label class='control-label col-md-3' for='LANGUAGE'>_{LANGUAGE}_</label>
  <div class='col-md-9'>
     %SEL_LANGUAGE%
  </div>
</div>

<div class='form-group'>
  <label class='control-label required col-md-3' for='LOGIN'>_{LOGIN}_</label>
  <div class='col-md-9'>
    <input id='LOGIN' name='LOGIN' value='%LOGIN%' required placeholder='_{LOGIN}_' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label required col-md-3' for='FIO'>_{FIO}_</label>
  <div class='col-md-9'>
    <input id='FIO' name='FIO' value='%FIO%' required placeholder='_{FIO}_' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label required col-md-3' for='PHONE'>_{PHONE}_</label>
  <div class='col-md-9'>
    <input id='FIO' name='PHONE' value='%PHONE%' required placeholder='_{PHONE}_' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='EMAIL'>E-MAIL</label>
  <div class='col-md-9'>
    <input id='FIO' name='EMAIL' value='%EMAIL%' placeholder='E-mail' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_</label>
  <div class='col-md-9'>
    %TP_SEL%
  </div>
</div>

%ADDRESS_TPL%

%PAYMENTS%

<div class='form-group text-center'>
  <label class='control-element col-md-12 ' for='TP_ID'>_{RULES}_</label>
  <div class='col-md-12'>
    <textarea cols=60 rows=8 class='form-control' readonly> %_RULES_% </textarea>
  </div>
</div>

<div class='form-group'>
  <label class='control-elenement col-md-7 required text-right' for='ACCEPT_RULES'>_{ACCEPT}_</label>
  <div class='col-md-5'>
    <input type='checkbox' required name='ACCEPT_RULES' value='1'>
  </div>
</div>

%CAPTCHA%
</div>

<div class='card-footer text-right'>
    <input type=submit name=reg value='_{REGISTRATION}_' class='btn btn-primary'>
</div>

</div>
</FORM>


%MAPS%

