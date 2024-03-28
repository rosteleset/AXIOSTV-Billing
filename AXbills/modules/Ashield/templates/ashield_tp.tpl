<div class='d-print-none'>

<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=TP_ID value='%TP_ID%'>

<div class='card card-primary card-outline box-form form-horizontal'>
<div class='card-header with-border'>_{TARIF_PLAN}_</div>
<div class='card-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>#</label>
    <label class='col-md-9 control-label'>%TP_ID%</label>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{NAME}_</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=NAME value='%NAME%' size=30>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{UPLIMIT}_</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=ALERT value='%ALERT%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{GROUP}_</label>
    <div class='col-md-9'>
      %GROUPS_SEL%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{MONTH_FEE}_</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=MONTH_FEE value='%MONTH_FEE%'>
    </div>
  </div>
  <hr>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{ACTIVATE}_</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{CHANGE}_</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{PAYMENT_TYPE}_</label>
    <div class='col-md-9'>
      %PAYMENT_TYPE_SEL%
    </div>
  </div>
  <hr>
  <div class='form-group'>
    <div class='checkbox'>
      <label>
        <input type='checkbox' name=DRWEB_GROUP value=1 %DRWEB_GROUP%>_{CREATE}_ _{GROUP}_ Dr. Web
      </label>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>Dr. Web ID:</label>
    <div class='col-md-9'>
      %DR_WEB_ID%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{GRACEPERIOD}_</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=DR_WEB_GRACE_PERIOD value=%DR_WEB_GRACE_PERIOD%>
    </div>
  </div>
  <hr>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{DESCRIBE}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' cols=55 rows=5 name=COMMENTS>%COMMENTS%</textarea>
    </div>
  </div>
</div>
<div class='card-footer'>
  <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
</div>
</div>




<!-- <table border=0 width=600>
  <tr><th colspan=2 class=form_title>_{TARIF_PLAN}_</th></tr>
  <tr><th>#</th><td>%TP_ID%</td></tr>
  <tr><td>_{NAME}_:</td><td><input type=text name=NAME value='%NAME%' size=30></td></tr>
  <tr><td>_{UPLIMIT}_:</td><td><input type=text name=ALERT value='%ALERT%'></td></tr>
  <tr><td>_{GROUP}_:</td><td>%GROUPS_SEL%</td></tr> -->
    <!--  <tr><td>_{DAY_FEE}_:</td><td><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr> -->
    <!-- <tr><td>_{MONTH_FEE}_:</td><td><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr> -->
    <!--  <tr><td>_{MONTH_ALIGNMENT}_:</td><td><input type=checkbox name=PERIOD_ALIGNMENT value='1' %PERIOD_ALIGNMENT%></td></tr> -->
<!--   <tr><th colspan=2 bgcolor=$_COLORS[0]>-</th></tr>
  <tr><td>_{ACTIVATE}_:</td><td><input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'></td></tr>
    <tr><td>_{CHANGE}_:</td><td><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></td></tr> -->
    <!--  <tr><td>_{AGE}_ (_{DAYS}_):</td><td><input type=text name=AGE value='%AGE%'></td></tr> -->
    <!--   <tr><td>_{PAYMENT_TYPE}_:</td><td>%PAYMENT_TYPE_SEL%</td></tr>
      <tr><th colspan=2 bgcolor=$_COLORS[0]>Dr.Web</th></tr>
      <tr><td>_{CREATE}_ _{GROUP}_ Dr. Web:</td><td><input type=checkbox name=DRWEB_GROUP value=1 %DRWEB_GROUP%></td></tr>
      <tr><td>Dr. Web ID:</td><td>%DR_WEB_ID%</td></tr>
      <tr><td>_{GRACEPERIOD}_:</td><td><input type=text name=DR_WEB_GRACE_PERIOD value=%DR_WEB_GRACE_PERIOD%></td></tr>
      <tr><th colspan=2 bgcolor=$_COLORS[2]>_{DESCRIBE}_</th></tr>
      <tr><th colspan=2><textarea cols=55 rows=5 name=COMMENTS>%COMMENTS%</textarea></th></tr>

    <tr><th class=even colspan=2><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
    </table> -->
</form>


</div>

