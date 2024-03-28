<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=MAIL_DOMAIN_ID value=$FORM{MAIL_DOMAIN_ID}>

<div class='card card-primary card-outline card-form form-horizontal'>
  <div class='card-header with-border'>
    <h2 class='card-title'>E-mail _{DOMAIN}_</h2>
  </div>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{DOMAIN}_:</label>
      <div class='col-md-9'>
        <input class='form-control' type=text name=DOMAIN value='%DOMAIN%' size=40>
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{TRANSPORT}_:</label>
      <div class='col-md-9'>
        %TRANSPORT_SEL%
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-md-3 control-label' for='BACKUP_MX'>Backup MX</label>
      <div class='col-md-9'>
        <input type='checkbox' id='BACKUP_MX' name=BACKUP_MX value='1' %BACKUP_MX%>
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-md-3 control-label' for='DISABLE'>_{DISABLE}_</label>
      <div class='col-md-9'>
        <input type='checkbox' id='DISABLE' name=DISABLE value='1' %DISABLE%>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{COMMENTS}_:</label>
      <div class='col-md-9'>
        <textarea class='form-control' name=COMMENTS cols=40 rows=5>
          %COMMENTS%
        </textarea>
      </div>
    </div>
  </div>

  <div class='card-footer'>
    <input class='btn btn-primary' type=submit name=%ACTION% value='%LNG_ACTION%'>
  </div>
</div>



<!-- <table class=form>
<tr><th class=form_title colspan=2>E-mail domains</th></tr>
<tr><td>_{DOMAIN}_:</td><td><input type=text name=DOMAIN value='%DOMAIN%' size=40></td></tr>
<tr><td>_{TRANSPORT}_:</td><td>%TRANSPORT_SEL%</td></tr>
<tr><td>Backup MX:</td><td><input type=checkbox name=BACKUP_MX value='1' %BACKUP_MX%></td></tr>
<tr><td>_{DISABLE}_:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><th colspan=2>:_{COMMENTS}_:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS cols=40 rows=5>%COMMENTS%</textarea></th></tr>
<tr><th class=even colspan=2><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table> -->

</form>
